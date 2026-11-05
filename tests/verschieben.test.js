// Aufgabe entfernen: Der Orga-Bereich fragt, ob sie gelöscht oder in eine andere
// Veranstaltung verschoben wird. Verschoben wird erst beim Speichern.
const test = require("node:test");
const assert = require("node:assert/strict");
const { ladeSeite, warte } = require("./seite");

async function editor(id){
  const s = ladeSeite("orga.html");
  const w = s.window, $ = x => w.document.getElementById(x);
  await s.geladen;
  $("key").value = "demo"; $("login").click();
  await warte(() => !$("view-list").classList.contains("hidden"), "Übersicht");
  await w.eval(`openEditor(events.find(e => e.id === "${id}"))`);
  await warte(() => !$("view-edit").classList.contains("hidden"), "Editor");
  return { s, w, $ };
}
const zeile = (w, label) => [...w.document.querySelectorAll("#tasks > .item")]
  .find(d => d.querySelector(".t-label").value === label);
const fs = w => w.eval(`demoEvents.find(e => e.id === "e-fs").tasks.map(t => t.label)`);

test("Aufgabe verschieben: erst beim Speichern, mit Hinweis auf Zusagen", async () => {
  const { s, w, $ } = await editor("e-neu");
  try{
    zeile(w, "Aufbau").querySelector(".drop").click();
    assert.ok(!$("aufgabe-dialog").classList.contains("hidden"), "Dialog offen");
    assert.match($("ad-zusagen").textContent, /1 Familie hat schon zugesagt/);
    const ziele = [...$("ad-ziel").options].map(o => o.textContent);
    assert.ok(ziele.some(t => /^Familiensamstag/.test(t)));
    assert.ok(!ziele.some(t => /Oma-Opa-Tag 2025/.test(t)), "archivierte nicht als Ziel");
    $("ad-ziel").value = "e-fs";
    $("ad-verschieben").click();
    assert.ok($("aufgabe-dialog").classList.contains("hidden"));
    assert.equal(zeile(w, "Aufbau"), undefined, "hier entfernt");
    assert.match(w.document.querySelector(".zurueck").textContent, /Aufbau \(nach Familiensamstag\)/);
    assert.deepEqual([...fs(w)], ["Zaun streichen"], "noch nicht verschoben");

    $("save").click();
    await warte(() => /Verschoben/.test($("edit-msg").textContent), "Meldung");
    assert.match($("edit-msg").textContent, /„Aufbau“ nach Familiensamstag/);
    assert.deepEqual([...fs(w)], ["Zaun streichen", "Aufbau"]);
    const t = w.eval(`demoEvents.find(e => e.id === "e-fs").tasks[1]`);
    assert.equal(t.needed, 6);
    assert.equal(t.when, "ab 12 Uhr");
    assert.ok(!w.eval(`demoEvents.find(e => e.id === "e-neu").tasks`).some(x => x.label === "Aufbau"));

    // nochmal speichern verschiebt nicht doppelt
    $("save").click();
    await warte(() => !$("save").disabled && /Gespeichert/.test($("edit-msg").textContent), "zweites Speichern");
    assert.deepEqual([...fs(w)], ["Zaun streichen", "Aufbau"]);
    assert.deepEqual(s.fehler, []);
  }finally{ s.schliessen(); }
});

test("Rückgängig hebt das Verschieben auf", async () => {
  const { s, w, $ } = await editor("e-neu");
  try{
    zeile(w, "Aufbau").querySelector(".drop").click();
    $("ad-ziel").value = "e-fs";
    $("ad-verschieben").click();
    w.document.querySelector(".zurueck button").click();
    assert.ok(zeile(w, "Aufbau"), "wieder da");
    $("save").click();
    await warte(() => /Gespeichert/.test($("edit-msg").textContent), "Speichern");
    assert.deepEqual([...fs(w)], ["Zaun streichen"]);
    assert.doesNotMatch($("edit-msg").textContent, /Verschoben/);
  }finally{ s.schliessen(); }
});

test("Nur löschen und Abbrechen", async () => {
  const { s, w, $ } = await editor("e-neu");
  try{
    zeile(w, "Aufbau").querySelector(".drop").click();
    $("ad-abbruch").click();
    assert.ok(zeile(w, "Aufbau"), "Abbrechen lässt sie stehen");
    zeile(w, "Aufbau").querySelector(".drop").click();
    $("ad-loeschen").click();
    assert.equal(zeile(w, "Aufbau"), undefined);
    $("save").click();
    await warte(() => /Gespeichert/.test($("edit-msg").textContent), "Speichern");
    assert.deepEqual([...fs(w)], ["Zaun streichen"]);
    assert.deepEqual(s.fehler, []);
  }finally{ s.schliessen(); }
});

test("Gleichnamige Aufgabe am Ziel wird nicht doppelt angelegt", async () => {
  const { s, w, $ } = await editor("e-neu");
  try{
    w.eval(`demoEvents.find(e => e.id === "e-fs").tasks.push({ id:"aufbau", label:"Aufbau", needed:2 })`);
    zeile(w, "Aufbau").querySelector(".drop").click();
    $("ad-ziel").value = "e-fs";
    $("ad-verschieben").click();
    $("save").click();
    await warte(() => /Verschoben/.test($("edit-msg").textContent), "Meldung");
    assert.deepEqual([...fs(w)], ["Zaun streichen", "Aufbau"]);
  }finally{ s.schliessen(); }
});

test("In Vorlagen wird ohne Rückfrage entfernt", async () => {
  const s = ladeSeite("orga.html");
  const w = s.window, $ = x => w.document.getElementById(x);
  try{
    await s.geladen;
    $("key").value = "demo"; $("login").click();
    await warte(() => !$("view-list").classList.contains("hidden"), "Übersicht");
    $("tab-templates").click();
    w.document.querySelector("#tlist [data-tact=edit]").click();
    await warte(() => $("t-tasks").children.length > 0, "Vorlage");
    const vorher = $("t-tasks").children.length;
    $("t-tasks").children[0].querySelector(".drop").click();
    assert.equal($("t-tasks").children.length, vorher - 1);
    assert.ok($("aufgabe-dialog").classList.contains("hidden"));
  }finally{ s.schliessen(); }
});
