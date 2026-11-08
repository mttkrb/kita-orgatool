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

test("Druckansicht: Namen kürzen zum Teilen mit den Eltern", async () => {
  const { s, w, $ } = await anmeldungen(`
    events.find(e => e.id === "e-neu").tasks = [{ id:"aufbau", label:"Aufbau", needed:2 }];
  `);
  try{
    $("dienstplan").click();
    assert.equal($("dp-tabelle").querySelectorAll("tr")[1].lastElementChild.textContent, "Tim Bergmann");
    $("dp-kurz").checked = true;
    $("dp-kurz").dispatchEvent(new w.Event("change"));
    assert.equal($("dp-tabelle").querySelectorAll("tr")[1].lastElementChild.textContent, "Tim B.");
    assert.deepEqual(s.fehler, []);
  }finally{ s.schliessen(); }
});

// Anmeldeseite nach Anmeldeschluss: Dienstplan mit Zusagen, freie Plätze nimmt man am Tag
const { fakeDb, SUPABASE } = require("./fake-db");
const FEST = { id:"e1", slug:"fest", title:"Sommerfest", event_on:"2099-06-20", signup_until:"2000-01-01",
  categories:[], fields:[], visibility:{ taskNames:true },
  tasks:[{ id:"aufbau", label:"Aufbau", needed:2 }, { id:"kuchen", label:"Kuchentheke", needed:1 }] };
const ZUSAGE = { id:"s1", event:"fest", token:"token-a-123456", name:"Anna Berg", adults:1, kids:0,
  items:[], tasks:["aufbau", "kuchen"], fields:{}, status:null };

async function eltern(ev, start = {}){
  const db = fakeDb({ events:[ev], signups:[ZUSAGE], ...start });
  const s = ladeSeite("fest-anmeldung.html", { supabase:SUPABASE, fetch:db.fetch, query:"?event=fest" });
  const $ = id => s.window.document.getElementById(id);
  await warte(() => $("tasks").querySelector(".task"), "Dienstplan");
  return { s, db, $ };
}

test("Anmeldeseite nach Schluss: Dienstplan mit Zusagen und Eintragen am Tag", async () => {
  const { s, db, $ } = await eltern(FEST, { task_claims:[{ id:"c1", event_id:"e1", task_id:"aufbau", name:"Ben Kurz", done:false }] });
  try{
    assert.equal($("tasks-head").textContent, "Dienstplan");
    assert.ok(!$("tasks-section").classList.contains("hidden"));
    const [aufbau, kuchen] = [...$("tasks").querySelectorAll(".task")];
    assert.match(text(aufbau), /Anna B\./);
    assert.match(text(aufbau), /Ben Kurz/);
    assert.ok(!aufbau.querySelector("[data-nehmen]"), "voll: kein Eintragen");
    assert.match(text(kuchen), /voll.*Anna B\./);

    // Plätze frei machen: Aufbau braucht 3
    s.window.eval("EV.tasks[0].needed = 3; renderTasks()");
    const feld = $("tasks").querySelector('[data-name="aufbau"]');
    feld.value = "Cem Neu";
    $("tasks").querySelector('[data-nehmen="aufbau"]').click();
    await warte(() => db.task_claims.length === 2, "eingetragen");
    assert.equal(db.task_claims[1].name, "Cem Neu");
    assert.equal(db.task_claims[1].task_id, "aufbau");
    await warte(() => /Cem Neu/.test($("tasks").textContent), "angezeigt");
    assert.deepEqual(db.unbekannt || [], []);
  }finally{ s.schliessen(); }
});

test("Anmeldeseite nach Schluss ohne Namen: nur die Zahl der Familien", async () => {
  const { s, $ } = await eltern({ ...FEST, visibility:{ taskNames:false, itemNames:false } });
  try{
    assert.match(text($("tasks").querySelector(".task")), /1 Familie eingetragen/);
    assert.doesNotMatch($("tasks").textContent, /Anna/);
  }finally{ s.schliessen(); }
});

test("Anmeldeseite vor Schluss: kein Dienstplan, Auswahl im Formular", async () => {
  const { fakeDb: neu } = require("./fake-db");
  const db = neu({ events:[{ ...FEST, signup_until:"2099-01-01" }], signups:[ZUSAGE] });
  const s = ladeSeite("fest-anmeldung.html", { supabase:SUPABASE, fetch:db.fetch, query:"?event=fest" });
  const $ = id => s.window.document.getElementById(id);
  try{
    await warte(() => $("task-checks").querySelector("input"), "Formular");
    assert.ok($("tasks-section").classList.contains("hidden"));
  }finally{ s.schliessen(); }
});
