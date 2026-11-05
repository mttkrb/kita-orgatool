// Zahlung erlassen: nur im Orga-Bereich. Das Orgateam hakt bei einer Anmeldung "Zahlung
// erlassen" an, etwa für Erzieherinnen und Erzieher. Sie bleiben in der Liste und kosten nichts.
const test = require("node:test");
const assert = require("node:assert/strict");
const { ladeSeite, warte } = require("./seite");
const { fakeDb, SUPABASE, ORGA } = require("./fake-db");

const SARAH = { id:"s1", event:"fest", token:"token-sarah-1234", name:"Sarah Klein", adults:2, kids:1,
  items:[], tasks:[], fields:{}, note:"", status:null };

test("Nachbau: Erlass lesen und setzen nur mit Orga-Passwort", async () => {
  const db = fakeDb({ signups:[SARAH], fee_waivers:[{ signup_id:"s1" }] });
  const url = SUPABASE.url + "/rest/v1/fee_waivers?select=signup_id&signup_id=eq.s1";
  const h = { apikey:SUPABASE.anonKey };
  assert.deepEqual(await (await db.fetch(url, { headers:h })).json(), [], "anon liest nichts");
  assert.deepEqual(await (await db.fetch(url, { headers:{ ...h, "X-Entry-Token":SARAH.token } })).json(), [],
    "auch das eigene Token liest nichts");
  const post = await db.fetch(SUPABASE.url + "/rest/v1/fee_waivers", { method:"POST",
    headers:{ ...h, "X-Entry-Token":SARAH.token }, body:JSON.stringify({ signup_id:"s1" }) });
  assert.equal(post.status, 403, "Eltern erlassen sich nicht selbst");
  assert.equal((await (await db.fetch(url, { headers:{ ...h, "X-Orga-Key":ORGA } })).json()).length, 1);
});

async function anmeldungen(){
  const s = ladeSeite("orga.html");
  const w = s.window, $ = id => w.document.getElementById(id);
  await s.geladen;
  $("key").value = "demo"; $("login").click();
  await warte(() => !$("view-list").classList.contains("hidden"), "Übersicht");
  await w.eval(`openSignups(events.find(e => e.id === "e-neu"))`);
  await warte(() => $("su-table").querySelector("[data-erlass]"), "Liste");
  return { s, w, $ };
}

test("Liste: Zahlung erlassen abhaken und zurücknehmen", async () => {
  const { s, w, $ } = await anmeldungen();
  try{
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
    $("nur-offen").click();
    await warte(() => /Alles bezahlt/.test($("su-table").textContent), "Filter");
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

test("Anmeldung eintragen mit Zahlung erlassen", async () => {
  const { s, w, $ } = await anmeldungen();
  try{
    $("manual").click();
    assert.ok(!$("m-erlass-box").classList.contains("hidden"), "Haken sichtbar, weil es etwas kostet");
    assert.equal($("m-erlass").checked, false);
    $("m-name").value = "Erzieherin Beispiel";
    $("m-adults").value = "1";
    $("m-erlass").checked = true;
    $("m-save").click();
    await warte(() => /Erzieherin Beispiel/.test($("su-table").textContent), "eingetragen");
    const neu = w.eval(`demoSignups.find(x => x.name === "Erzieherin Beispiel")`);
    assert.ok(!("erlassen" in neu), "Erlass geht nicht in die Anmeldung");
    assert.deepEqual([...w.eval("demoWaivers")], [neu.id]);
    assert.match($("totals").textContent, /1Zahlung erlassen/);
    assert.match($("totals").textContent, /31,50\s€Einnahmen \(Soll\)/, "Soll unverändert");

    // Bearbeiten zeigt den Haken und nimmt ihn zurück
    $("su-table").querySelector('[data-edit="' + neu.id + '"]').click();
    assert.equal($("m-erlass").checked, true);
    $("m-erlass").checked = false;
    $("m-save").click();
    await warte(() => !/Zahlung erlassen\b(?! \()/.test($("totals").textContent) && w.eval("demoWaivers.length") === 0, "zurück");
    assert.match($("totals").textContent, /34,50\s€Einnahmen \(Soll\)/);
    assert.deepEqual(s.fehler, []);
  }finally{ s.schliessen(); }
});
