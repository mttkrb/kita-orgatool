// Entscheidungen: Thema, Entscheidung und Warum, im Rückblick gespeichert. Beim nächsten
// Mal aus derselben Vorlage stehen sie unter "Aus den letzten Malen".
const test = require("node:test");
const assert = require("node:assert/strict");
const { ladeSeite, warte } = require("./seite");

async function orga(){
  const s = ladeSeite("orga.html");
  const w = s.window, $ = x => w.document.getElementById(x);
  await s.geladen;
  $("key").value = "demo"; $("login").click();
  await warte(() => !$("view-list").classList.contains("hidden"), "Übersicht");
  return { s, w, $ };
}

test("Entscheidung eintragen, speichern, Datum bleibt", async () => {
  const { s, w, $ } = await orga();
  try{
    await w.eval(`openEditor(events.find(e => e.id === "e-neu"))`);
    await warte(() => !$("view-edit").classList.contains("hidden"), "Editor");
    // Die Einträge bleiben dauerhaft, deshalb der Hinweis wie bei den Spenden
    assert.match($("entscheidungen").closest("fieldset").querySelector(".hint").textContent,
      /Ohne Namen von Privatpersonen/);
    $("add-entscheidung").click();
    const d = $("entscheidungen").lastElementChild;
    d.querySelector(".en-thema").value = "Motto";
    d.querySelector(".en-ergebnis").value = "Piraten";
    d.querySelector(".en-warum").value = "Die Kinder haben abgestimmt";
    $("save").click();
    await warte(() => /Gespeichert/.test($("edit-msg").textContent), "Speichern");
    const e = w.eval(`planning.review.entscheidungen`);
    assert.equal(e.length, 1);
    assert.equal(e[0].thema, "Motto");
    assert.equal(e[0].ergebnis, "Piraten");
    assert.equal(e[0].warum, "Die Kinder haben abgestimmt");
    assert.equal(e[0].datum, w.eval("heute()"));

    // Neu öffnen mit älterem Datum: Datum bleibt beim Speichern stehen
    w.eval(`demoPlanning["e-neu"].review.entscheidungen[0].datum = "2026-01-15"`);
    await w.eval(`openEditor(events.find(e => e.id === "e-neu"))`);
    await warte(() => $("entscheidungen").children.length === 1, "geladen");
    assert.match($("entscheidungen").textContent, /Motto:.*Piraten.*15\.1\.2026/);
    assert.equal(w.eval("collectPlanning()").review.entscheidungen[0].datum, "2026-01-15");
    assert.deepEqual(s.fehler, []);
  }finally{ s.schliessen(); }
});

test("Aus den letzten Malen zeigt die Entscheidungen, als Text", async () => {
  const { s, w, $ } = await orga();
  try{
    w.eval(`demoPlanning["e-alt"].review.entscheidungen.push(
      { id:"en2", thema:"<b>Kuchen</b>", ergebnis:"Spendenbuffet", warum:"", datum:"2025-09-02" })`);
    $("tab-templates").click();
    w.document.querySelector("#tlist [data-tact=use]").click();
    await warte(() => /Aus den letzten Malen/.test($("history").textContent), "Historie");
    const text = $("history").textContent;
    assert.match(text, /Ort: Kita-Außengelände mit Pavillon — Gemeindesaal war belegt/);
    assert.match(text, /<b>Kuchen<\/b>: Spendenbuffet/, "fremde Eingabe als Text");
    assert.equal($("history").querySelectorAll(".entsch li").length, 2);
    assert.deepEqual(s.fehler, []);
  }finally{ s.schliessen(); }
});
