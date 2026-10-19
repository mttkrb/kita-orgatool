// Projekte nur fürs Orgateam (visibility.intern): nicht in der Übersicht, keine Seite für
// Eltern, nicht auf der Meldeseite. Im Orga-Bereich ein eigener Editor-Modus.
const test = require("node:test");
const assert = require("node:assert/strict");
const { ladeSeite, warte } = require("./seite");
const { fakeDb, SUPABASE } = require("./fake-db");

const FEST = { id:"e1", slug:"fest", title:"Sommerfest", event_on:"2099-06-20", archived:false,
  categories:[], tasks:[], fields:[] };
const GESCHENK = { id:"e2", slug:"geschenk", title:"Abschiedsgeschenk Frau Müller", event_on:"2099-06-10",
  archived:false, categories:[], tasks:[], fields:[], visibility:{ intern:true } };

test("Übersicht zeigt Projekte nur fürs Orgateam nicht", async () => {
  const db = fakeDb({ events:[FEST, GESCHENK] });
  const s = ladeSeite("index.html", { supabase:SUPABASE, fetch:db.fetch });
  const $ = id => s.window.document.getElementById(id);
  try{
    await warte(() => $("list").children.length, "Karten");
    const text = $("list").textContent;
    assert.ok(text.includes("Sommerfest"));
    assert.ok(!text.includes("Frau Müller"));
    assert.deepEqual(s.fehler, []);
  }finally{ s.schliessen(); }
});

test("Anmeldeseite eines Projekts nur fürs Orgateam zeigt weder Titel noch Formular", async () => {
  const db = fakeDb({ events:[GESCHENK] });
  const s = ladeSeite("fest-anmeldung.html", { supabase:SUPABASE, fetch:db.fetch, query:"?event=geschenk" });
  const $ = id => s.window.document.getElementById(id);
  try{
    await warte(() => $("ev-title").textContent.includes("nicht öffentlich"), "Hinweis");
    assert.ok($("main").classList.contains("hidden"));
    assert.ok(!s.window.document.title.includes("Müller"));
    assert.ok(!s.window.document.querySelector(".wrap").textContent.includes("Müller"));
    assert.ok(!db.anfragen.some(a => a.url.includes("anmeldungen_oeffentlich")), "keine Anmeldungen geladen");
    assert.deepEqual(s.fehler, []);
  }finally{ s.schliessen(); }
});

test("Meldeseite bietet Projekte nur fürs Orgateam nicht an", async () => {
  const db = fakeDb({ events:[FEST, GESCHENK] });
  const s = ladeSeite("vorschlag.html", { supabase:SUPABASE, fetch:db.fetch });
  const $ = id => s.window.document.getElementById(id);
  try{
    await warte(() => $("fest").options.length && $("fest").options[0].value, "Terminauswahl");
    const termine = [...$("fest").options].map(o => o.textContent);
    assert.ok(termine.some(t => t.includes("Sommerfest")));
    assert.ok(!termine.some(t => t.includes("Müller")));
  }finally{ s.schliessen(); }
});

test("Orga-Bereich: neues Projekt blendet alles für Eltern aus und speichert intern", async () => {
  const s = ladeSeite("orga.html");
  const w = s.window, $ = id => w.document.getElementById(id);
  const sichtbar = el => !el.classList.contains("hidden") && !el.closest(".hidden");
  try{
    await s.geladen;
    $("key").value = "demo"; $("login").click();
    await warte(() => sichtbar($("view-list")), "Übersicht");
    $("new-intern").click();
    await warte(() => sichtbar($("view-edit")), "Editor");
    assert.equal($("e-intern").checked, true);
    assert.equal($("edit-title").textContent, "Neues Projekt");
    for(const id of ["e-p-adults", "v-totals", "cats", "fields", "e-released", "e-days", "copy-link", "copy-melde"])
      assert.ok(!sichtbar($(id)), id + " ausgeblendet");
    for(const id of ["e-title", "e-on", "e-intro", "checks", "einkauf", "save"])
      assert.ok(sichtbar($(id)), id + " sichtbar");
    $("e-title").value = "Abschiedsgeschenk";
    assert.equal(w.eval("collectEvent()").visibility.intern, true);
    // Haken weg: wieder eine normale Veranstaltung
    $("e-intern").click();
    assert.ok(sichtbar($("cats")) && sichtbar($("copy-link")));
    assert.equal(w.eval("collectEvent()").visibility.intern, false);
    assert.deepEqual(s.fehler, []);
  }finally{ s.schliessen(); }
});
