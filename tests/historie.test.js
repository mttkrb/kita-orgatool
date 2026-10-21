// Historie im Orga-Bereich: Rückblick einer Veranstaltung ohne Anmeldungen (nach der
// Löschfrist oder nachgetragen) zeigt die festgehaltenen Zahlen und lässt sie bearbeiten.
// Speichern setzt sie nicht mehr auf 0, und gespeicherte Geldwerte bleiben stehen.
const test = require("node:test");
const assert = require("node:assert/strict");
const { ladeSeite, warte } = require("./seite");

async function orga(){
  const s = ladeSeite("orga.html");
  const w = s.window, $ = id => w.document.getElementById(id);
  await s.geladen;
  $("key").value = "demo"; $("login").click();
  await warte(() => !$("view-list").classList.contains("hidden"), "Übersicht");
  return { s, w, $ };
}
const sichtbar = el => !el.classList.contains("hidden") && !el.closest(".hidden");
const setze = (w, el, v) => { el.value = v; el.dispatchEvent(new w.Event("input", { bubbles:true })); };

test("Vergangene Veranstaltung nachtragen: archiviert, Zahlen von Hand", async () => {
  const { s, w, $ } = await orga();
  try{
    $("tab-templates").click();
    w.document.querySelector("#tlist [data-tact=hist]").click();
    await warte(() => sichtbar($("view-edit")) && sichtbar($("r-archiv")), "Editor im Archivmodus");
    assert.equal($("e-archived").checked, true);
    assert.match($("edit-sub").textContent, /nachtragen/);
    setze(w, $("r-a-zusagen"), "33"); setze(w, $("r-a-absagen"), "1");
    setze(w, $("r-a-erw"), "85"); setze(w, $("r-a-kinder"), "50");
    assert.equal($("r-expected").value, "135");
    setze(w, w.document.querySelector("#r-a-aufgaben [data-rtask=aufbau]"), "9");
    setze(w, $("r-a-ein"), "459"); setze(w, $("r-a-bez"), "440.5");
    const p = w.eval("collectPlanning()");
    assert.equal(p.review.zahlen.anmeldungen, 33);
    assert.equal(p.review.zahlen.absagen, 1);
    assert.equal(p.review.zahlen.erwachsene, 85);
    assert.equal(p.review.zahlen.kinder, 50);
    assert.equal(p.review.zahlen.aufgaben.aufbau, 9);
    assert.match(p.review.zahlen.gepflegt, /^\d{4}-\d\d-\d\d$/);
    assert.equal(p.review.expected, 135);
    assert.equal(p.review.geld.einnahmen, 459);
    assert.equal(p.review.geld.bezahlt, 440.5);
    assert.equal(w.eval("collectEvent()").archived, true);
    assert.deepEqual(s.fehler, []);
  }finally{ s.schliessen(); }
});

test("Nach der Löschfrist: festgehaltene Zahlen bleiben, Bearbeiten ändert nur das Bearbeitete", async () => {
  const { s, w, $ } = await orga();
  try{
    await w.eval(`(async () => {
      demoSignups = demoSignups.filter(x => x.event !== "oma-opa-tag-2025");
      demoPlanning["e-alt"].review.zahlen = { stand:"2025-11-01", anmeldungen:20, absagen:2,
        erwachsene:30, kinder:10, kategorien:{ herzhaft:5 }, aufgaben:{ aufbau:4 }, anwesend:18 };
      demoPlanning["e-alt"].review.geld = { einnahmen:100, bezahlt:90, stand:"2025-11-01" };
      await openEditor(events.find(e => e.id === "e-alt"));
    })()`);
    await warte(() => sichtbar($("r-archiv")), "Archivmodus");
    assert.equal($("r-a-zusagen").value, "20");
    assert.equal($("r-a-absagen").value, "2");
    assert.equal($("r-expected").value, "40");
    assert.equal(w.document.querySelector("#r-a-aufgaben [data-rtask=aufbau]").value, "4");
    assert.equal($("r-a-bez").value, "90");
    assert.match($("r-a-stand").textContent, /1\.11\.2025/);
    assert.ok(!sichtbar($("r-geld")), "berechnete Geldanzeige aus");
    setze(w, $("r-a-kinder"), "12");
    const p = w.eval("collectPlanning()");
    assert.equal(p.review.zahlen.kinder, 12);
    assert.equal(p.review.zahlen.anmeldungen, 20, "nicht auf 0 gesetzt");
    assert.equal(p.review.zahlen.anwesend, 18, "nicht angefasste Zahlen bleiben");
    assert.equal(JSON.stringify(p.review.zahlen.kategorien), JSON.stringify({ herzhaft:5 }));
    assert.equal(p.review.expected, 42);
    assert.equal(p.review.geld.einnahmen, 100);
    assert.equal(p.review.geld.bezahlt, 90);
    assert.deepEqual(s.fehler, []);
  }finally{ s.schliessen(); }
});

test("Laufende Veranstaltung: kein Archivmodus, Speichern behält bezahlt", async () => {
  const { s, w, $ } = await orga();
  try{
    await w.eval(`(async () => {
      demoPlanning["e-neu"] = { checklist:[], shopping:[], review:{ geld:{ bezahlt:50 } } };
      await openEditor(events.find(e => e.id === "e-neu"));
    })()`);
    await warte(() => sichtbar($("view-edit")), "Editor");
    assert.ok(!sichtbar($("r-archiv")));
    const p = w.eval("collectPlanning()");
    assert.equal(p.review.geld.bezahlt, 50);
    assert.ok(p.review.expected > 0);
    assert.equal(p.review.zahlen, undefined);
    assert.deepEqual(s.fehler, []);
  }finally{ s.schliessen(); }
});

test("Historie zeigt nachgepflegte Zahlen samt Absagen", async () => {
  const { s, w, $ } = await orga();
  try{
    await w.eval(`(async () => {
      demoSignups = demoSignups.filter(x => x.event !== "oma-opa-tag-2025");
      demoPlanning["e-alt"].review = { guests:40,
        zahlen:{ anmeldungen:25, absagen:3, erwachsene:46, kinder:0 } };
    })()`);
    $("tab-templates").click();
    w.document.querySelector("#tlist [data-tact=use]").click();
    await warte(() => $("history").textContent.includes("Absagen"), "Historie");
    const text = $("history").textContent;
    assert.match(text, /25 Anmeldungen, 3 Absagen, 40 Personen/);
    assert.match(text, /angemeldet: 46/);
    assert.deepEqual(s.fehler, []);
  }finally{ s.schliessen(); }
});
