// Zahlung erlassen: Das Orgateam hakt bei einer Anmeldung "Zahlung erlassen" an, etwa
// für Erzieherinnen und Erzieher. Sie bleiben in der Liste und kosten nichts.
const test = require("node:test");
const assert = require("node:assert/strict");
const { ladeSeite, warte } = require("./seite");
const { fakeDb, SUPABASE, ORGA } = require("./fake-db");

const EVENT = { id:"e1", slug:"fest", title:"Sommerfest", event_on:"2099-06-20",
  categories:[], tasks:[], fields:[], payment:{ adults:3, kids:2 } };
const SARAH = { id:"s1", event:"fest", token:"token-sarah-1234", name:"Sarah Klein", adults:2, kids:1,
  items:[], tasks:[], fields:{}, note:"", status:null };
const TIM = { ...SARAH, id:"s2", token:"token-tim-12345", name:"Tim Berg" };

test("Nachbau: Erlass lesen und setzen nur mit Recht", async () => {
  const db = fakeDb({ signups:[SARAH, TIM], fee_waivers:[{ signup_id:"s1" }] });
  const url = SUPABASE.url + "/rest/v1/fee_waivers?select=signup_id&signup_id=eq.s1";
  const h = { apikey:SUPABASE.anonKey };
  assert.deepEqual(await (await db.fetch(url, { headers:h })).json(), [], "anon liest nichts");
  assert.deepEqual(await (await db.fetch(url, { headers:{ ...h, "X-Entry-Token":TIM.token } })).json(), [],
    "fremdes Token liest nichts");
  assert.equal((await (await db.fetch(url, { headers:{ ...h, "X-Entry-Token":SARAH.token } })).json()).length, 1,
    "eigenes Token liest den eigenen Erlass");
  const post = await db.fetch(SUPABASE.url + "/rest/v1/fee_waivers", { method:"POST",
    headers:{ ...h, "X-Entry-Token":TIM.token }, body:JSON.stringify({ signup_id:"s2" }) });
  assert.equal(post.status, 403, "Eltern erlassen sich nicht selbst");
  const orga = await db.fetch(SUPABASE.url + "/rest/v1/fee_waivers", { method:"POST",
    headers:{ ...h, "X-Orga-Key":ORGA }, body:JSON.stringify({ signup_id:"s2" }) });
  assert.equal(orga.status, 201);
  assert.equal(db.fee_waivers.length, 2);
});

async function elternseite(start){
  const db = fakeDb({ events:[EVENT], signups:[SARAH], ...start });
  const s = ladeSeite("fest-anmeldung.html", { supabase:SUPABASE, fetch:db.fetch,
    query:"?event=fest&entry=" + SARAH.token + "&sid=s1" });
  const $ = id => s.window.document.getElementById(id);
  await warte(() => $("f-name").value === "Sarah Klein", "Formular gefüllt");
  return { s, db, $ };
}

test("Anmeldeseite: erlassen heißt Du zahlst nichts", async () => {
  const { s, db, $ } = await elternseite({ fee_waivers:[{ signup_id:"s1" }] });
  try{
    await warte(() => /Du zahlst nichts/.test($("kosten-box").textContent), "Hinweis");
    assert.doesNotMatch($("kosten-box").textContent, /Gesamt/);
    const abruf = db.anfragen.find(a => a.url.includes("/fee_waivers"));
    assert.equal(abruf.kopf["x-entry-token"], SARAH.token);
    $("form").requestSubmit();
    await warte(() => !$("done").classList.contains("hidden"), "Bestätigung");
    assert.match($("done").textContent, /Du zahlst nichts/);
    assert.doesNotMatch($("done").textContent, /bezahlen/i);
    const patch = db.anfragen.find(a => a.methode === "PATCH");
    assert.ok(!("erlassen" in patch.body), "Erlass geht nicht mit in die Anmeldung");
    assert.deepEqual(db.unbekannt || [], []);
  }finally{ s.schliessen(); }
});

test("Anmeldeseite ohne Erlass zeigt den Betrag", async () => {
  const { s, $ } = await elternseite({});
  try{
    await warte(() => /Gesamt/.test($("kosten-box").textContent), "Betrag");
    assert.match($("kosten-box").textContent, /8,00/);
    assert.doesNotMatch($("kosten-box").textContent, /Du zahlst nichts/);
  }finally{ s.schliessen(); }
});

test("Orga-Bereich: Zahlung erlassen abhaken", async () => {
  const s = ladeSeite("orga.html");
  const w = s.window, $ = id => w.document.getElementById(id);
  try{
    await s.geladen;
    $("key").value = "demo"; $("login").click();
    await warte(() => !$("view-list").classList.contains("hidden"), "Übersicht");
    await w.eval(`openSignups(events.find(e => e.id === "e-neu"))`);
    await warte(() => $("su-table").querySelector("[data-erlass]"), "Liste");
    // Soll vorher: Tim 18,50 + Anne 13,00
    assert.match($("totals").textContent, /31,50\s€Einnahmen \(Soll\)/);
    const haken = $("su-table").querySelector('[data-erlass="s3"]');
    haken.checked = true;
    haken.dispatchEvent(new w.Event("change", { bubbles:true }));
    await warte(() => /1Zahlung erlassen/.test($("totals").textContent), "Summe");
    assert.match($("totals").textContent, /18,50\s€Einnahmen \(Soll\)/);
    assert.match($("totals").textContent, /0,00\s€offen/);
    assert.deepEqual([...w.eval("demoWaivers")], ["s3"]);
    assert.match($("su-table").textContent, /Zahlung erlassen \(statt 13,00/);
    // Nur offene Zahlungen: Anne fällt raus
    $("nur-offen").click();
    await warte(() => /Alles bezahlt/.test($("su-table").textContent), "Filter");
    // Zurücknehmen
    $("nur-offen").click();
    await warte(() => $("su-table").querySelector('[data-erlass="s3"]'), "Liste");
    const zurueck = $("su-table").querySelector('[data-erlass="s3"]');
    zurueck.checked = false;
    zurueck.dispatchEvent(new w.Event("change", { bubbles:true }));
    await warte(() => /31,50\s€Einnahmen/.test($("totals").textContent), "wieder Soll");
    assert.deepEqual([...w.eval("demoWaivers")], []);
    assert.deepEqual(s.fehler, []);
  }finally{ s.schliessen(); }
});
