// fest-anmeldung.html gegen den Nachbau der Datenbank: anmelden, über den
// persönlichen Link ändern, abmelden mit und ohne Zahlung.
const test = require("node:test");
const assert = require("node:assert/strict");
const { ladeSeite, warte } = require("./seite");
const { fakeDb, SUPABASE } = require("./fake-db");

const EVENT = { id:"e1", slug:"fest", title:"Sommerfest", event_on:"2099-06-20",
  categories:[{ id:"kuchen", label:"Kuchen" }], tasks:[], fields:[] };
const SARAH = { id:"s1", event:"fest", token:"token-sarah-1234", name:"Sarah Klein", adults:2, kids:1,
  items:[{ cat:"kuchen", what:"Käsekuchen" }], tasks:[], fields:{}, note:"privat", status:null };

async function seite(start, query = "?event=fest"){
  const db = fakeDb({ events:[EVENT], ...start });
  const s = ladeSeite("fest-anmeldung.html", { supabase:SUPABASE, fetch:db.fetch, query });
  const $ = id => s.window.document.getElementById(id);
  await warte(() => !$("main").classList.contains("hidden") && $("status").textContent, "Seite geladen");
  return { s, db, $ };
}
const absenden = $ => $("form").requestSubmit();
const sichtbar = el => !el.classList.contains("hidden");
// Was jede Seite einhalten muss, egal was der Test tut
function grundregeln(db, s, erlaubt = []){
  assert.ok(!db.anfragen.some(a => /[?&]token=/.test(a.url)), "nie nach token filtern");
  assert.deepEqual(db.unbekannt || [], []);
  assert.deepEqual(s.fehler.filter(f => !erlaubt.some(e => f.includes(e))), []);
}

test("Nachbau ist nicht freundlicher als die Datenbank", async () => {
  const db = fakeDb({ signups:[SARAH] });
  const h = { apikey:SUPABASE.anonKey };
  const r1 = await db.fetch(SUPABASE.url + "/rest/v1/signups?select=id&token=eq." + SARAH.token, { headers:h });
  assert.equal(r1.status, 403);
  assert.equal((await r1.json()).code, "42501");
  const r2 = await db.fetch(SUPABASE.url + "/rest/v1/signups?select=id,name", { headers:h });
  assert.deepEqual(await r2.json(), [], "anon ohne Token liest keine Anmeldungen");
  const r3 = await db.fetch(SUPABASE.url + "/rest/v1/signups?select=id&id=eq.s1",
    { headers:{ ...h, "X-Entry-Token":"falsch-1234" } });
  assert.deepEqual(await r3.json(), [], "falsches Token liest nichts");
});

test("Liste zeigt gekürzte Namen, keine Anmerkungen", async () => {
  const { s, db } = await seite({ signups:[SARAH] });
  try{
    // Nur der sichtbare Teil; das Skript der Seite enthält Demodaten
    const text = s.window.document.querySelector(".wrap").textContent;
    assert.ok(text.includes("Sarah K."));
    assert.ok(!text.includes("Sarah Klein"));
    assert.ok(!text.includes("privat"));
    assert.ok(!db.anfragen.some(a => a.methode === "GET" && a.url.includes("/signups")),
      "ohne persönlichen Link keine direkte Abfrage der Anmeldungen");
    grundregeln(db, s);
  }finally{ s.schliessen(); }
});

test("Neue Anmeldung landet in der Datenbank, Seite zeigt persönlichen Link", async () => {
  const { s, db, $ } = await seite();
  try{
    $("f-name").value = "Tim Bergmann";
    $("f-consent").checked = true;
    absenden($);
    await warte(() => sichtbar($("done")), "Bestätigung");
    assert.equal(db.signups.length, 1);
    const neu = db.signups[0];
    assert.equal(neu.name, "Tim Bergmann");
    assert.equal(neu.event, "fest");
    assert.match(neu.token, /^[0-9a-f]{16}$/);
    assert.ok($("done").textContent.includes("https://kita.test/orga/fest-anmeldung.html?event=fest&entry=" +
      neu.token + "&sid=" + neu.id), "persönlicher Link relativ zur Seite");
    grundregeln(db, s);
  }finally{ s.schliessen(); }
});

test("Ohne Einwilligung wird nichts gespeichert", async () => {
  const { s, db, $ } = await seite();
  try{
    $("f-name").value = "Tim Bergmann";
    absenden($);
    await warte(() => sichtbar($("error")), "Fehlermeldung");
    assert.equal(db.signups.length, 0);
    grundregeln(db, s);
  }finally{ s.schliessen(); }
});

test("Persönlicher Link liest und ändert über id und Token im Header", async () => {
  const { s, db, $ } = await seite({ signups:[SARAH] }, "?event=fest&entry=" + SARAH.token + "&sid=s1");
  try{
    await warte(() => $("f-name").value === "Sarah Klein", "Formular gefüllt");
    assert.equal($("f-note").value, "privat");
    $("f-name").value = "Sarah Klein-Berg";
    absenden($);
    await warte(() => sichtbar($("done")), "Bestätigung");
    assert.equal(db.signups.length, 1);
    assert.equal(db.signups[0].name, "Sarah Klein-Berg");
    const patch = db.anfragen.find(a => a.methode === "PATCH");
    assert.match(patch.url, /\/signups\?select=id&id=eq\.s1$/);
    assert.equal(patch.kopf["x-entry-token"], SARAH.token);
    grundregeln(db, s);
  }finally{ s.schliessen(); }
});

test("Fremdes Token füllt das Formular nicht", async () => {
  const { s, db, $ } = await seite({ signups:[SARAH] }, "?event=fest&entry=falsch-1234&sid=s1");
  try{
    await new Promise(r => setTimeout(r, 100));
    assert.equal($("f-name").value, "");
    grundregeln(db, s);
  }finally{ s.schliessen(); }
});

async function abmelden(start){
  const r = await seite(start, "?event=fest&entry=" + SARAH.token + "&sid=s1");
  const { $ } = r;
  await warte(() => $("f-name").value === "Sarah Klein", "Formular gefüllt");
  absenden($);
  await warte(() => $("remove"), "Knopf Abmelden");
  $("remove").click();
  return r;
}

test("Abmelden ohne Zahlung löscht die Anmeldung", async () => {
  const { s, db } = await abmelden({ signups:[SARAH] });
  try{
    await warte(() => db.signups.length === 0, "gelöscht");
    // Danach lädt die Seite neu; Navigation kennt jsdom nicht
    await warte(() => s.fehler.some(f => f.includes("navigation")), "Neuladen");
    grundregeln(db, s, ["navigation"]);
  }finally{ s.schliessen(); }
});

test("Abmelden mit Zahlung lässt Anmeldung und Zahlung stehen", async () => {
  const { s, db, $ } = await abmelden({ signups:[SARAH], payments:[{ signup_id:"s1", amount:12 }] });
  try{
    await warte(() => sichtbar($("error")), "Fehlermeldung");
    assert.match($("error").textContent, /schon bezahlt/);
    assert.equal(db.signups.length, 1);
    assert.equal(db.payments.length, 1);
    grundregeln(db, s);
  }finally{ s.schliessen(); }
});
