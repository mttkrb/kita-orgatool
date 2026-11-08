// Fremde Eingaben erscheinen auf allen fünf Seiten als Text, nie als HTML.
// Jede Angabe, die Eltern, Melder oder das Orgateam eintippen können, bekommt dieselbe
// Zeichenkette mit Tag und Attribut-Ausbruch. Danach darf keine Seite ein Element daraus
// gebaut haben: kein <img src="x">, kein Attribut onerror, kein Skript gelaufen.
const test = require("node:test");
const assert = require("node:assert/strict");
const { ladeSeite, warte } = require("./seite");
const { fakeDb, SUPABASE } = require("./fake-db");

const BOESE = `"'><img src=x onerror="globalThis.xss=1">`;
// Ein Foto, das aus dem Attribut src ausbrechen will
const BOESES_BILD = `data:image/png;base64,x" onerror="globalThis.xss=1`;

function nichtsAusgefuehrt(s, wo){
  const d = s.window.document;
  assert.equal(d.querySelectorAll('img[src="x"]').length, 0, wo + ": <img> aus Eingabe gebaut");
  assert.equal(d.querySelectorAll("[onerror]").length, 0, wo + ": Attribut onerror aus Eingabe");
  assert.equal(s.window.xss, undefined, wo + ": Skript aus Eingabe gelaufen");
}
const zeigtText = (s, wo) => assert.ok(s.window.document.body.textContent.includes(BOESE),
  wo + ": Eingabe nicht als Text sichtbar");

const EVENT = { id:"e1", slug:"fest", title:BOESE, event_on:"2099-06-20", place:BOESE,
  event_time:BOESE, intro:BOESE,
  categories:[{ id:"kuchen", label:BOESE, target:5, unit:BOESE, ideas:[BOESE] }],
  tasks:[{ id:"aufbau", label:BOESE, when:BOESE, info:BOESE, needed:3 }],
  fields:[{ id:"frei", label:BOESE, type:"text" },
          { id:"wahl", label:"Auswahl", type:"select", options:[BOESE, "nein"] }],
  visibility:{ totals:true, itemNames:true, taskNames:true } };
// Einwortnamen, damit der gekürzte Name die ganze Zeichenkette zeigt
const NAME = BOESE.replace(/ /g, "_");
const ANMELDUNG = { id:"s1", event:"fest", token:"t-1", name:NAME, adults:1, kids:0,
  items:[{ cat:"kuchen", what:BOESE }], tasks:["aufbau"], fields:{ [BOESE]:BOESE }, note:BOESE, status:null };

test("index.html zeigt Veranstaltung und Kategorien als Text", async () => {
  const db = fakeDb({ events:[EVENT], signups:[ANMELDUNG] });
  const s = ladeSeite("index.html", { supabase:SUPABASE, fetch:db.fetch });
  const $ = id => s.window.document.getElementById(id);
  await warte(() => $("list").children.length > 0, "Liste");
  zeigtText(s, "index");
  nichtsAusgefuehrt(s, "index");
  assert.deepEqual(s.fehler, []);
});

test("fest-anmeldung.html zeigt Namen, Mitbringsel, Aufgaben und Zusatzfragen als Text", async () => {
  const db = fakeDb({ events:[EVENT], signups:[ANMELDUNG],
    task_claims:[{ id:"c1", event_id:"e1", task_id:"aufbau", name:BOESE, done:false }] });
  const s = ladeSeite("fest-anmeldung.html", { supabase:SUPABASE, fetch:db.fetch, query:"?event=fest" });
  const $ = id => s.window.document.getElementById(id);
  await warte(() => !$("main").classList.contains("hidden") && $("status").textContent, "Seite geladen");
  await warte(() => s.window.document.body.textContent.includes(NAME), "Namen in der Liste");
  zeigtText(s, "Anmeldung");
  nichtsAusgefuehrt(s, "Anmeldung");
  assert.deepEqual(s.fehler, []);
});

test("fest-anmeldung.html: Aufgaben vor Ort, Übernahmen mit Namen", async () => {
  const vorOrt = { ...EVENT, visibility:{ ...EVENT.visibility, taskSignup:false } };
  const db = fakeDb({ events:[vorOrt], signups:[ANMELDUNG],
    task_claims:[{ id:"c1", event_id:"e1", task_id:"aufbau", name:BOESE, done:false }] });
  const s = ladeSeite("fest-anmeldung.html", { supabase:SUPABASE, fetch:db.fetch, query:"?event=fest" });
  const $ = id => s.window.document.getElementById(id);
  await warte(() => !$("tasks-section").classList.contains("hidden") &&
    $("tasks-section").textContent.includes(BOESE), "Aufgaben vor Ort");
  zeigtText(s, "Aufgaben vor Ort");
  nichtsAusgefuehrt(s, "Aufgaben vor Ort");
  assert.deepEqual(s.fehler, []);
});

test("fest-anmeldung.html: persönlicher Link mit eigenen Angaben", async () => {
  const db = fakeDb({ events:[EVENT], signups:[ANMELDUNG] });
  const s = ladeSeite("fest-anmeldung.html", { supabase:SUPABASE, fetch:db.fetch,
    query:"?event=fest&entry=t-1&sid=s1" });
  const $ = id => s.window.document.getElementById(id);
  await warte(() => $("f-name").value === NAME, "eigene Anmeldung geladen");
  assert.equal($("f-note").value, BOESE);
  nichtsAusgefuehrt(s, "persönlicher Link");
  assert.deepEqual(s.fehler, []);
});

test("vorschlag.html zeigt Termine und gemeldete Aufgaben als Text", async () => {
  const db = fakeDb({ events:[EVENT],
    proposals:[{ event_id:"e1", title:BOESE, info:BOESE, needed:2, from_name:BOESE, status:"neu" }] });
  const s = ladeSeite("vorschlag.html", { supabase:SUPABASE, fetch:db.fetch });
  const $ = id => s.window.document.getElementById(id);
  await warte(() => !$("schon").classList.contains("hidden"), "Schon gemeldet");
  zeigtText(s, "Melden");
  nichtsAusgefuehrt(s, "Melden");
  assert.equal($("fest").options[0].textContent.startsWith(BOESE), true);
  assert.deepEqual(db.unbekannt || [], []);
  assert.deepEqual(s.fehler, []);
});

test("feedback.html zeigt den Titel als Text", async () => {
  const db = fakeDb({ events:[EVENT] });
  const s = ladeSeite("feedback.html", { supabase:SUPABASE, fetch:db.fetch, query:"?event=e1" });
  const $ = id => s.window.document.getElementById(id);
  await warte(() => $("titel").textContent.includes(BOESE), "Titel");
  nichtsAusgefuehrt(s, "Rückmeldung");
  assert.deepEqual(s.fehler, []);
});

test("orga.html zeigt Anmeldungen, Rückmeldungen, Meldungen und Rückblick als Text", async () => {
  const s = ladeSeite("orga.html");
  const w = s.window, $ = id => w.document.getElementById(id);
  await s.geladen;
  // Demo-Daten mit der Zeichenkette in jedem Feld, das jemand eintippen kann
  await w.eval(`(() => {
    const B = ${JSON.stringify(BOESE)}, BILD = ${JSON.stringify(BOESES_BILD)};
    const ev = demoEvents.find(e => e.id === "e-neu");
    Object.assign(ev, { title:B, place:B, event_time:B,
      fields:ev.fields.concat([{ id:"frei", label:"Anmerkung zum Essen", type:"text" }]),
      visibility:{ feedback:true } });
    ev.categories[0].label = B; ev.tasks[0].label = B; ev.tasks[0].info = B;
    demoSignups.push({ id:"s9", event:ev.slug, created_at:new Date().toISOString(), name:B,
      adults:1, kids:0, items:[{ cat:"kuchen", what:B }], tasks:["aufbau"],
      fields:{ "Anmerkung zum Essen":B }, note:B });
    demoPlanning["e-neu"].review = { notes:B,
      entscheidungen:[{ id:"en9", thema:B, ergebnis:B, warum:B, datum:"2026-01-01" }] };
    demoPlanning["e-neu"].checklist = [{ id:"c9", label:B, who:B, due:B, done:false }];
    demoPlanning["e-neu"].shopping.push({ id:"k9", menge:"1", einheit:B, artikel:B, wer:B, preis:1, done:false });
    demoReceipts.push({ id:"rc9", event_id:"e-neu", shop:B, bought_on:"2026-01-01", amount:1, item_id:null,
      image:"data:image/jpeg;base64,/9j/AAAA", created_at:new Date().toISOString() });
    const meldung = { id:"p9", event_id:"e-neu", title:B, info:B, needed:2, from_name:B,
      image:BILD, status:"neu", created_at:new Date().toISOString() };
    db.proposals = async () => [meldung];
    db.proposalsOffen = async () => [meldung];
    db.feedback = async () => [{ id:"f9", good:B, better:B, from_name:B, rating:4,
      created_at:new Date().toISOString() }];
  })()`);
  $("key").value = "demo"; $("login").click();
  await warte(() => !$("view-list").classList.contains("hidden"), "Übersicht");
  await warte(() => w.document.body.textContent.includes(BOESE), "Cockpit mit Meldung");
  nichtsAusgefuehrt(s, "Orga-Übersicht");

  await w.eval(`openEditor(events.find(e => e.id === "e-neu"))`);
  await warte(() => !$("view-edit").classList.contains("hidden"), "Editor");
  await warte(() => $("vorschlaege").textContent.includes(BOESE), "Meldungen im Editor");
  $("v-feedback").checked = true;
  await w.eval(`renderFeedback()`);
  await warte(() => $("feedback-box").textContent.includes(BOESE), "Rückmeldungen");
  nichtsAusgefuehrt(s, "Orga-Editor");

  await w.eval(`openSignups(events.find(e => e.id === "e-neu"))`);
  await warte(() => w.document.body.textContent.includes(BOESE) &&
    !$("view-signups").classList.contains("hidden"), "Anmeldungen");
  nichtsAusgefuehrt(s, "Orga-Anmeldungen");
  assert.deepEqual(s.fehler, []);
});
