// Höchstzahl je Veranstaltung: people.limit zählt Erwachsene und Kinder zusammen.
// Gilt nur auf der Anmeldeseite. Ist alles belegt, gibt es dort keine neue Anmeldung mehr;
// wer schon angemeldet ist, ändert oder sagt ab. Das Orgateam trägt weiter ein.
const test = require("node:test");
const assert = require("node:assert/strict");
const { ladeSeite, warte } = require("./seite");
const { fakeDb, SUPABASE } = require("./fake-db");

const EVENT = { id:"e1", slug:"fest", title:"Sommerfest", event_on:"2099-06-20",
  categories:[], tasks:[], fields:[], people:{ limit:6 } };
const SARAH = { id:"s1", event:"fest", token:"token-sarah-1234", name:"Sarah Klein", adults:2, kids:1,
  items:[], tasks:[], fields:{}, note:"", status:null };
const TIM = { id:"s2", event:"fest", token:"token-tim-12345", name:"Tim Bergmann", adults:1, kids:1,
  items:[], tasks:[], fields:{}, note:"", status:null };
const ANNE = { id:"s3", event:"fest", token:"token-anne-1234", name:"Anne Vogt", adults:2, kids:2,
  items:[], tasks:[], fields:{}, note:"", status:"absage" };

async function seite(start, query = "?event=fest", event = EVENT){
  const db = fakeDb({ events:[event], ...start });
  const s = ladeSeite("fest-anmeldung.html", { supabase:SUPABASE, fetch:db.fetch, query });
  const $ = id => s.window.document.getElementById(id);
  await warte(() => !$("main").classList.contains("hidden") && $("status").textContent, "Seite geladen");
  return { s, db, $ };
}
const sichtbar = el => !el.classList.contains("hidden");
const formular = $ => $("form").closest("section");
const optionen = el => [...el.options].map(o => +o.value);

test("common.js: freie Plätze ohne Absagen, ohne Grenze null", async () => {
  const s = ladeSeite("index.html");
  try{
    await s.geladen;
    const w = s.window;
    assert.equal(w.eval("freiePlaetze({ people:{} }, [])"), null);
    assert.equal(w.eval("freiePlaetze({ people:{ limit:'abc' } }, [])"), null);
    assert.equal(w.eval(`freiePlaetze({ people:{ limit:10 } }, [
      { adults:2, kids:1 }, { adults:3, kids:2, status:"absage" }, { adults:"1", kids:null }])`), 6);
    assert.equal(w.eval("freiePlaetze({ people:{ limit:3 } }, [{ adults:4, kids:1 }])"), 0, "überbucht = 0");
    assert.equal(w.eval("plaetzeText(null)"), "");
    assert.equal(w.eval("plaetzeText(0)"), "Ausgebucht");
    assert.equal(w.eval("plaetzeText(1)"), "noch 1 Platz frei");
    assert.equal(w.eval("plaetzeText(12)"), "noch 12 Plätze frei");
    // ohne Gesamtzahlen keine Zahl, die die Belegung verrät
    const ohne = "{ people:{ limit:40 }, visibility:{ totals:false } }";
    assert.equal(w.eval("plaetzeText(20, " + ohne + ")"), "");
    assert.equal(w.eval("plaetzeText(5, " + ohne + ")"), "nur noch wenige Plätze frei");
    assert.equal(w.eval("plaetzeText(0, " + ohne + ")"), "Ausgebucht");
    assert.equal(w.eval("plaetzeText(12, { people:{ limit:40 }, visibility:{ totals:true } })"), "noch 12 Plätze frei");
    assert.equal(w.eval("wenigePlaetze({ people:{ limit:40 } })"), 5);
    assert.equal(w.eval("wenigePlaetze({ people:{ limit:200 } })"), 20);
  }finally{ s.schliessen(); }
});

test("Anmeldeseite zeigt freie Plätze und begrenzt die Auswahl", async () => {
  const { s, db, $ } = await seite({ signups:[SARAH, ANNE] });
  try{
    assert.match($("ev-count").textContent, /noch 3 Plätze frei/);
    assert.ok(sichtbar(formular($)));
    assert.ok(!sichtbar($("anmelde-hinweis")));
    assert.deepEqual(optionen($("f-adults")), [0,1,2,3]);
    assert.match($("plaetze-hint").textContent, /Noch 3 Plätze frei, Erwachsene und Kinder zusammen/);
    // 3 + 1 = 4 Personen passen nicht
    $("f-name").value = "Tim Bergmann";
    $("f-adults").value = "3"; $("f-kids").value = "1";
    $("f-consent").checked = true;
    $("form").requestSubmit();
    await warte(() => sichtbar($("error")), "Fehler");
    assert.match($("error").textContent, /nur noch 3 Plätze frei/);
    assert.equal(db.signups.length, 2);
    $("f-adults").value = "2"; $("f-kids").value = "1";
    $("form").requestSubmit();
    await warte(() => sichtbar($("done")), "angemeldet");
    assert.equal(db.signups.length, 3);
    assert.deepEqual(s.fehler, []);
  }finally{ s.schliessen(); }
});

test("Ausgebucht: kein Formular für neue Anmeldungen", async () => {
  const { s, db, $ } = await seite({ signups:[SARAH, { ...TIM, adults:2, kids:1 }] });
  try{
    assert.match($("ev-count").textContent, /Ausgebucht/);
    assert.ok(sichtbar($("anmelde-hinweis")));
    assert.match($("anmelde-hinweis-text").textContent, /Ausgebucht\. Alle Plätze sind vergeben/);
    assert.ok(!sichtbar(formular($)));
    assert.ok(!db.anfragen.some(a => a.methode === "POST" && a.url.includes("/signups")));
    assert.deepEqual(s.fehler, []);
  }finally{ s.schliessen(); }
});

test("Ausgebucht: eigene Anmeldung ändern und absagen geht", async () => {
  const voll = [SARAH, { ...TIM, adults:2, kids:1 }];
  const { s, db, $ } = await seite({ signups:voll }, "?event=fest&entry=" + SARAH.token + "&sid=s1");
  try{
    await warte(() => $("f-name").value === "Sarah Klein", "eigene Anmeldung");
    assert.ok(sichtbar(formular($)));
    assert.ok(!sichtbar($("anmelde-hinweis")));
    // die eigenen 3 Plätze stehen wieder zur Wahl
    assert.deepEqual(optionen($("f-adults")), [0,1,2,3]);
    assert.equal($("f-adults").value, "2");
    $("f-adults").value = "1";
    $("form").requestSubmit();
    await warte(() => sichtbar($("done")), "gespeichert");
    assert.equal(db.signups.find(x => x.id === "s1").adults, 1);
    assert.deepEqual(s.fehler, []);
  }finally{ s.schliessen(); }
  const zwei = await seite({ signups:voll }, "?event=fest&entry=" + SARAH.token + "&sid=s1");
  try{
    await warte(() => zwei.$("f-name").value === "Sarah Klein", "eigene Anmeldung");
    zwei.$("w-nein").click();
    zwei.$("form").requestSubmit();
    await warte(() => sichtbar(zwei.$("done")), "abgesagt");
    assert.equal(zwei.db.signups.find(x => x.id === "s1").status, "absage");
    assert.deepEqual(zwei.s.fehler, []);
  }finally{ zwei.s.schliessen(); }
});

test("Ausgebucht: wer abgesagt hat, sagt nicht wieder zu", async () => {
  const abgesagt = { ...SARAH, status:"absage", adults:0, kids:0 };
  const { s, db, $ } = await seite({ signups:[abgesagt, { ...TIM, adults:4, kids:2 }] },
    "?event=fest&entry=" + SARAH.token + "&sid=s1");
  try{
    await warte(() => $("f-name").value === "Sarah Klein", "eigene Anmeldung");
    $("w-ja").click();
    $("form").requestSubmit();
    await warte(() => sichtbar($("error")), "Fehler");
    assert.match($("error").textContent, /ausgebucht/);
    assert.equal(db.signups.find(x => x.id === "s1").status, "absage");
  }finally{ s.schliessen(); }
});

test("Verbindliche Veranstaltung ausgebucht: Absagen bleibt möglich", async () => {
  const ev = { ...EVENT, mandatory:true };
  const { s, db, $ } = await seite({ signups:[SARAH, { ...TIM, adults:2, kids:1 }] }, "?event=fest", ev);
  try{
    assert.ok(sichtbar(formular($)));
    assert.match($("anmelde-hinweis-text").textContent, /Absagen kannst du hier weiterhin/);
    $("f-name").value = "Jonas Peters";
    $("f-consent").checked = true;
    $("form").requestSubmit();
    await warte(() => sichtbar($("error")), "Zusage abgelehnt");
    assert.equal(db.signups.length, 2);
    $("w-nein").click();
    $("f-grund").value = "Urlaub";
    $("form").requestSubmit();
    await warte(() => sichtbar($("done")), "abgesagt");
    assert.equal(db.signups.length, 3);
    assert.deepEqual(s.fehler, []);
  }finally{ s.schliessen(); }
});

test("Ohne Grenze bleibt alles wie bisher", async () => {
  const ev = { ...EVENT, people:{} };
  const { s, $ } = await seite({ signups:[SARAH] }, "?event=fest", ev);
  try{
    assert.doesNotMatch($("ev-count").textContent, /frei|Ausgebucht/);
    assert.ok(!sichtbar($("plaetze-hint")));
    assert.deepEqual(optionen($("f-adults")), [0,1,2,3,4,5,6]);
  }finally{ s.schliessen(); }
});

test("Startseite zeigt freie Plätze und Ausgebucht", async () => {
  const offen = { ...EVENT };
  const voll = { ...EVENT, id:"e2", slug:"voll", title:"Laternenfest", people:{ limit:2 } };
  const db = fakeDb({ events:[offen, voll],
    signups:[SARAH, ANNE, { ...TIM, event:"voll" }] });
  const s = ladeSeite("index.html", { supabase:SUPABASE, fetch:db.fetch });
  const $ = id => s.window.document.getElementById(id);
  try{
    await warte(() => $("list").children.length === 2, "Liste");
    const [a, b] = [...$("list").children].map(c => c.textContent);
    assert.match(a, /noch 3 Plätze frei/);
    assert.match(b, /Ausgebucht/);
    assert.doesNotMatch(b, /Anmelden und/);
    assert.deepEqual(s.fehler, []);
  }finally{ s.schliessen(); }
});

test("Orga: Plätze insgesamt speichern und Belegung zeigen, ohne zu sperren", async () => {
  const s = ladeSeite("orga.html");
  const w = s.window, $ = id => w.document.getElementById(id);
  try{
    await s.geladen;
    w.eval(`fillGroups("e", { people:{ limit:40 } })`);
    assert.equal($("e-limit").value, "40");
    assert.equal(w.eval(`readGroups("e").limit`), 40);
    $("e-limit").value = "";
    assert.equal(w.eval(`"limit" in readGroups("e")`), false, "leer = keine Grenze");
    $("t-limit").value = "25";
    assert.equal(w.eval(`readGroups("t").limit`), 25);

    $("key").value = "demo"; $("login").click();
    await warte(() => !$("view-list").classList.contains("hidden"), "Übersicht");
    // Grenze kleiner als die Anmeldungen: anzeigen, nichts sperren
    await w.eval(`(() => { const e = events.find(e => e.id === "e-neu");
      e.people = { ...(e.people||{}), limit:3 }; return openSignups(e); })()`);
    await warte(() => /Plätzen belegt/.test($("totals").textContent), "Belegung");
    assert.match($("totals").textContent, /\d+ von 3Plätzen belegt \(ausgebucht\)/);
    assert.deepEqual(s.fehler, []);
  }finally{ s.schliessen(); }
});

test("Ohne Gesamtzahlen: keine Zahl freier Plätze auf Anmelde- und Startseite", async () => {
  const ohne = { ...EVENT, visibility:{ totals:false } };
  const { s, db, $ } = await seite({ signups:[SARAH, ANNE] }, "?event=fest", ohne);
  try{
    // 3 von 6 frei: knapp
    assert.equal($("ev-count").textContent, "Nur noch wenige Plätze frei");
    assert.doesNotMatch($("main").textContent, /\d+ Pl(atz|ätze) frei/);
    assert.ok(!sichtbar($("plaetze-hint")));
    $("f-name").value = "Tim Bergmann";
    $("f-adults").value = "3"; $("f-kids").value = "1";
    $("f-consent").checked = true;
    $("form").requestSubmit();
    await warte(() => sichtbar($("error")), "Fehler");
    assert.match($("error").textContent, /So viele Plätze sind nicht mehr frei/);
    assert.doesNotMatch($("error").textContent, /\d/);
    assert.equal(db.signups.length, 2);
    assert.deepEqual(s.fehler, []);
  }finally{ s.schliessen(); }

  const gross = { ...EVENT, visibility:{ totals:false }, people:{ limit:40 } };
  const voll = { ...EVENT, id:"e2", slug:"voll", title:"Laternenfest", people:{ limit:2 },
    visibility:{ totals:false } };
  const db2 = fakeDb({ events:[gross, voll], signups:[SARAH, { ...TIM, event:"voll" }] });
  const s2 = ladeSeite("index.html", { supabase:SUPABASE, fetch:db2.fetch });
  const $2 = id => s2.window.document.getElementById(id);
  try{
    await warte(() => $2("list").children.length === 2, "Liste");
    const [a, b] = [...$2("list").children].map(c => c.textContent);
    assert.doesNotMatch(a, /Plätze frei|Platz frei/, "viel frei: nichts");
    assert.match(b, /Ausgebucht/);
    assert.deepEqual(s2.fehler, []);
  }finally{ s2.schliessen(); }
});
