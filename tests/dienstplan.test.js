// Dienstplan in den Anmeldungen: je Aufgabe, wer sie übernimmt, aus den Haken im
// Anmeldeformular und den Übernahmen am Tag. Auch bei geschlossener Anmeldung sichtbar.
const test = require("node:test");
const assert = require("node:assert/strict");
const { ladeSeite, warte } = require("./seite");

async function anmeldungen(vorher = ""){
  const s = ladeSeite("orga.html");
  const w = s.window, $ = id => w.document.getElementById(id);
  await s.geladen;
  $("key").value = "demo"; $("login").click();
  await warte(() => !$("view-list").classList.contains("hidden"), "Übersicht");
  await w.eval(`(async () => { ${vorher}; await openSignups(events.find(e => e.id === "e-neu")); })()`);
  await warte(() => /Dienstplan/.test($("su-table").textContent), "Dienstplan");
  return { s, w, $ };
}
const text = el => el.textContent.replace(/\s+/g, " ").trim();

test("Dienstplan zeigt Zusagen und Übernahmen am Tag, auch bei geschlossener Anmeldung", async () => {
  const { s, w, $ } = await anmeldungen(`
    const ev = events.find(e => e.id === "e-neu");
    ev.signup_until = "2000-01-01";              // Anmeldung geschlossen
    ev.tasks = [{ id:"aufbau", label:"Aufbau", when:"ab 12 Uhr", needed:3 },
                { id:"g1", label:"Grillen", when:"9–10 Uhr", needed:2, group:"grillen" }];
    demoSignups.push({ id:"s9", event:"sommerfest-2026", name:"Ola Abgesagt", status:"absage",
      adults:0, kids:0, items:[], tasks:["aufbau"], fields:{}, created_at:"" });
    db.claims = async () => [{ id:"c1", task_id:"g1", name:"Carla Vorort", done:true }];
  `);
  try{
    const zeilen = [...$("su-table").querySelectorAll(".dp-zeile")].map(text);
    assert.equal(zeilen.length, 2);
    assert.match(zeilen[0], /^Aufbau ab 12 UhrTim Bergmann1 von 3, 2 frei$/);
    assert.doesNotMatch(zeilen[0], /Ola/, "Absagen zählen nicht");
    assert.match(zeilen[1], /^Grillen \(9–10 Uhr\)Carla Vorort ✓erledigt$/);
    assert.ok(!$("dienstplan").classList.contains("hidden"));
    assert.deepEqual(s.fehler, []);
  }finally{ s.schliessen(); }
});

test("Druckansicht: Tabelle mit freien Zeilen zum Eintragen, Namen als Text", async () => {
  const { s, w, $ } = await anmeldungen(`
    events.find(e => e.id === "e-neu").tasks = [{ id:"aufbau", label:"Aufbau", when:"ab 12 Uhr", needed:3 }];
    demoSignups.find(x => x.id === "s3").tasks = ["aufbau"];
    demoSignups.find(x => x.id === "s3").name = "<b>Anne</b> Vogt";
  `);
  try{
    $("dienstplan").click();
    assert.ok(!$("dienstplan-ansicht").classList.contains("hidden"));
    assert.match($("dp-titel").textContent, /Dienstplan Sommerfest/);
    const rows = [...$("dp-tabelle").querySelectorAll("tr")];
    assert.equal(rows.length, 4, "Kopf plus 3 Plätze");
    assert.equal(rows[1].querySelector("td").rowSpan, 3);
    const namen = rows.slice(1).map(r => r.lastElementChild.textContent);
    assert.deepEqual(namen, ["Tim Bergmann", "<b>Anne</b> Vogt", ""]);
    assert.equal($("dp-tabelle").querySelectorAll("b").length, 0, "fremde Eingabe nicht als HTML");
    assert.equal(rows[3].lastElementChild.className, "leer");
    $("dp-zu").click();
    assert.ok($("dienstplan-ansicht").classList.contains("hidden"));
    assert.deepEqual(s.fehler, []);
  }finally{ s.schliessen(); }
});

test("Ohne Aufgaben kein Dienstplan", async () => {
  const s = ladeSeite("orga.html");
  const w = s.window, $ = id => w.document.getElementById(id);
  try{
    await s.geladen;
    $("key").value = "demo"; $("login").click();
    await warte(() => !$("view-list").classList.contains("hidden"), "Übersicht");
    await w.eval(`(async () => { events.find(e => e.id === "e-neu").tasks = [];
      await openSignups(events.find(e => e.id === "e-neu")); })()`);
    await warte(() => /Tim Bergmann/.test($("su-table").textContent), "Liste");
    assert.doesNotMatch($("su-table").textContent, /Dienstplan/);
    assert.ok($("dienstplan").classList.contains("hidden"));
  }finally{ s.schliessen(); }
});
