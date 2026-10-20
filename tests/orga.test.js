// Kleinigkeiten im Orga-Bereich, die keine Datenbank brauchen.
const test = require("node:test");
const assert = require("node:assert/strict");
const { ladeSeite } = require("./seite");

test("Orga-Passwort lässt sich zeigen und wieder verbergen", async () => {
  const s = ladeSeite("orga.html");
  const $ = id => s.window.document.getElementById(id);
  try{
    await s.geladen;
    assert.equal($("key").type, "password");
    $("key-zeigen").click();
    assert.equal($("key").type, "text");
    assert.equal($("key-zeigen").textContent, "Verbergen");
    assert.equal($("key-zeigen").getAttribute("aria-pressed"), "true");
    $("key-zeigen").click();
    assert.equal($("key").type, "password");
    assert.equal($("key-zeigen").textContent, "Zeigen");
    assert.deepEqual(s.fehler, []);
  }finally{ s.schliessen(); }
});
