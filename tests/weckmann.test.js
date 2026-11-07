// Bestellartikel mit Grundmenge (St. Martin): je Kita-Kind ein Weckmann, dazu die bestellten.
// Dazu das Orga-Formular mit allen Zusatzfragen.
const test = require("node:test");
const assert = require("node:assert/strict");
const { ladeSeite, warte } = require("./seite");

const FELDER = `[
  { id:"kita", label:"Wie viele Kita-Kinder?", type:"number", required:false, options:[] },
  { id:"weckmann", label:"Extra-Weckmänner", type:"order", price:2.5, max:10, basis:"Wie viele Kita-Kinder?", options:[] }
]`;
async function orga(vorher){
  const s = ladeSeite("orga.html");
  const w = s.window, $ = id => w.document.getElementById(id);
  await s.geladen;
  $("key").value = "demo"; $("login").click();
  await warte(() => !$("view-list").classList.contains("hidden"), "Übersicht");
  await w.eval(`(async () => {
    const ev = events.find(e => e.id === "e-neu");
    ev.fields = ${FELDER};
    demoSignups.find(x => x.id === "s2").fields = { "Wie viele Kita-Kinder?":"2", "Extra-Weckmänner":"3" };
    demoSignups.find(x => x.id === "s3").fields = { "Wie viele Kita-Kinder?":"1" };
    demoSignups.push({ id:"s4", event:"sommerfest-2026", name:"Abgesagt", status:"absage", adults:1, kids:1,
      items:[], tasks:[], fields:{ "Wie viele Kita-Kinder?":"5", "Extra-Weckmänner":"5" }, created_at:"" });
    ${vorher || ""}
  })()`);
  return { s, w, $ };
}

test("Anmeldungen zeigen die Gesamtmenge: Kita-Kinder plus Bestellungen, ohne Absagen", async () => {
  const { s, w, $ } = await orga();
  try{
    await w.eval(`openSignups(events.find(e => e.id === "e-neu"))`);
    await warte(() => /gesamt/.test($("totals").textContent), "Summen");
    assert.match($("totals").textContent.replace(/\s+/g, " "),
      /6Extra-Weckmänner gesamt \(3 Wie viele Kita-Kinder\? \+ 3 bestellt\)/);
    // Grundmenge kostet nichts: Soll bleibt Personen + 3 × 2,50
    assert.deepEqual(s.fehler, []);
  }finally{ s.schliessen(); }
});

test("Editor: Grundmenge wählbar, gespeichert und im Rückblick festgehalten", async () => {
  const { s, w, $ } = await orga();
  try{
    await w.eval(`openEditor(events.find(e => e.id === "e-neu"))`);
    await warte(() => !$("view-edit").classList.contains("hidden"), "Editor");
    const zeilen = [...$("fields").children];
    const sel = zeilen[1].querySelector(".f-basis");
    assert.equal(sel.value, "Wie viele Kita-Kinder?");
    sel.dispatchEvent(new w.Event("focus"));
    assert.deepEqual([...sel.options].map(o => o.value), ["", "Wie viele Kita-Kinder?"], "nur Zahl-Fragen");
    const felder = w.eval("readFields($('fields'))");
    assert.equal(felder[1].basis, "Wie viele Kita-Kinder?");
    $("save").click();
    await warte(() => /Gespeichert/.test($("edit-msg").textContent), "Speichern");
    const b = w.eval(`planning.review.bestellungen["Extra-Weckmänner"]`);
    assert.equal(b.gesamt, 6);
    assert.equal(b.grund, 3);
    assert.equal(b.extra, 3);
    assert.deepEqual(s.fehler, []);
  }finally{ s.schliessen(); }
});

test("Aus den letzten Malen zeigt die Gesamtmenge", async () => {
  const { s, w, $ } = await orga(`
    const alt = events.find(e => e.id === "e-alt");
    alt.fields = ${FELDER};
    demoSignups.find(x => x.id === "s1").fields = { "Wie viele Kita-Kinder?":"1", "Extra-Weckmänner":"4" };
  `);
  try{
    $("tab-templates").click();
    w.document.querySelector("#tlist [data-tact=use]").click();
    await warte(() => /Aus den letzten Malen/.test($("history").textContent), "Historie");
    assert.match($("history").textContent, /Extra-Weckmänner: 5 gesamt \(1 Wie viele Kita-Kinder\? \+ 4 bestellt\)/);
    assert.deepEqual(s.fehler, []);
  }finally{ s.schliessen(); }
});

test("Orga-Formular: Zusatzfragen eintragen und beim Bearbeiten behalten", async () => {
  const { s, w, $ } = await orga();
  try{
    await w.eval(`openSignups(events.find(e => e.id === "e-neu"))`);
    await warte(() => $("su-table").querySelector("[data-edit]"), "Liste");
    $("manual").click();
    const kita = $("m-fields").querySelector('[data-mf="Wie viele Kita-Kinder?"]');
    assert.ok(kita, "Feld für Kita-Kinder da");
    $("m-name").value = "Neue Familie";
    kita.value = "4";
    $("m-orders").querySelector("[data-order]").value = "2";
    $("m-save").click();
    await warte(() => /Neue Familie/.test($("su-table").textContent), "eingetragen");
    const neu = w.eval(`demoSignups.find(x => x.name === "Neue Familie")`);
    assert.equal(neu.fields["Wie viele Kita-Kinder?"], "4");
    assert.equal(neu.fields["Extra-Weckmänner"], "2");
    assert.match($("totals").textContent.replace(/\s+/g, " "), /12Extra-Weckmänner gesamt \(7 .* \+ 5 bestellt\)/);

    // Bearbeiten zeigt die Antwort und behält sie
    $("su-table").querySelector('[data-edit="' + neu.id + '"]').click();
    assert.equal($("m-fields").querySelector('[data-mf="Wie viele Kita-Kinder?"]').value, "4");
    $("m-save").click();
    await warte(() => $("manual-form").classList.contains("hidden"), "gespeichert");
    assert.equal(w.eval(`demoSignups.find(x => x.name === "Neue Familie").fields["Wie viele Kita-Kinder?"]`), "4");
    assert.deepEqual(s.fehler, []);
  }finally{ s.schliessen(); }
});
