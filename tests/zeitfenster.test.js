// Aufgaben in Zeitfenstern: Im Editor wird aus "Grillen 9–13 Uhr, alle 60 Minuten, je 2"
// eine Reihe eigener Aufgaben mit gemeinsamem group. Die Anmeldeseite zeigt sie unter
// einer Überschrift; gezählt wird je Fenster.
const test = require("node:test");
const assert = require("node:assert/strict");
const { ladeSeite, warte } = require("./seite");
const { fakeDb, SUPABASE } = require("./fake-db");

async function editor(){
  const s = ladeSeite("orga.html");
  const w = s.window, $ = x => w.document.getElementById(x);
  await s.geladen;
  $("key").value = "demo"; $("login").click();
  await warte(() => !$("view-list").classList.contains("hidden"), "Übersicht");
  await w.eval(`openEditor(events.find(e => e.id === "e-neu"))`);
  await warte(() => !$("view-edit").classList.contains("hidden"), "Editor");
  return { s, w, $ };
}

test("Zeitfenster erzeugen: vier Aufgaben, je anpassbar, mit Gruppe gespeichert", async () => {
  const { s, w, $ } = await editor();
  try{
    $("add-task").click();
    const d = $("tasks").lastElementChild;
    d.querySelector(".t-label").value = "Grillen";
    d.querySelector(".t-info").value = "Würstchen wenden";
    d.querySelector(".s-von").value = "09:00";
    d.querySelector(".s-bis").value = "13:00";
    d.querySelector(".s-takt").value = "60";
    d.querySelector(".s-je").value = "2";
    d.querySelector(".s-los").click();

    const t = [...w.eval("readTasks($('tasks'))")].filter(x => x.label === "Grillen");
    assert.deepEqual([...t.map(x => x.when)], ["9–10 Uhr", "10–11 Uhr", "11–12 Uhr", "12–13 Uhr"]);
    assert.deepEqual([...t.map(x => x.id)], ["grillen-0900", "grillen-1000", "grillen-1100", "grillen-1200"]);
    assert.ok(t.every(x => x.group === "grillen" && x.needed === 2 && x.info === "Würstchen wenden"));
    assert.equal($("tasks").querySelectorAll(".t-slots").length, 1, "nur Aufbau hat noch das Werkzeug");

    // ein Fenster anpassen
    const zweites = [...$("tasks").children].find(x => x.dataset.id === "grillen-1000");
    zweites.querySelector(".t-needed").value = "3";
    $("save").click();
    await warte(() => /Gespeichert/.test($("edit-msg").textContent), "Speichern");
    const gespeichert = w.eval(`demoEvents.find(e => e.id === "e-neu").tasks`).filter(x => x.group === "grillen");
    assert.equal(gespeichert.length, 4);
    assert.equal(gespeichert[1].needed, 3);
    assert.deepEqual(s.fehler, []);
  }finally{ s.schliessen(); }
});

test("Halbe Stunden und ungerades Ende", async () => {
  const { s, w } = await editor();
  try{
    const l = w.eval(`zeitfensterListe("09:30", "11:00", 45).map(([a, b]) => uhr(a) + "–" + uhr(b))`);
    assert.deepEqual([...l], ["9:30–10:15", "10:15–11"]);
    assert.equal(w.eval(`zeitfensterListe("12:00", "11:00", 60).length`), 0);
  }finally{ s.schliessen(); }
});

test("Aufteilen mit Zusagen fragt nach", async () => {
  const { s, w, $ } = await editor();
  try{
    let gefragt = "";
    w.confirm = text => { gefragt = text; return false; };
    const aufbau = [...$("tasks").children].find(x => x.dataset.id === "aufbau");
    aufbau.querySelector(".s-los").click();
    assert.match(gefragt, /1 Familie hat für „Aufbau“ schon zugesagt/);
    assert.ok(aufbau.isConnected, "abgebrochen, Aufgabe bleibt");
  }finally{ s.schliessen(); }
});

test("Anmeldeseite: Zeitfenster unter einer Überschrift, je Fenster gezählt", async () => {
  const EVENT = { id:"e1", slug:"fest", title:"Sommerfest", event_on:"2099-06-20", categories:[], fields:[],
    tasks:[{ id:"aufbau", label:"Aufbau", needed:4 },
           { id:"grillen-0900", label:"Grillen", when:"9–10 Uhr", needed:2, group:"grillen", info:"Würstchen wenden" },
           { id:"grillen-1000", label:"Grillen", when:"10–11 Uhr", needed:2, group:"grillen", info:"Würstchen wenden" }] };
  const db = fakeDb({ events:[EVENT], signups:[
    { id:"s1", event:"fest", token:"token-a-123456", name:"Anna Berg", adults:1, kids:0, items:[],
      tasks:["grillen-0900"], fields:{}, status:null },
    { id:"s2", event:"fest", token:"token-b-123456", name:"Ben Kurz", adults:1, kids:0, items:[],
      tasks:["grillen-0900"], fields:{}, status:null }] });
  const s = ladeSeite("fest-anmeldung.html", { supabase:SUPABASE, fetch:db.fetch, query:"?event=fest" });
  const $ = id => s.window.document.getElementById(id);
  try{
    await warte(() => $("task-checks").querySelector(".slot-kopf"), "Aufgaben");
    const kopf = $("task-checks").querySelectorAll(".slot-kopf");
    assert.equal(kopf.length, 1);
    assert.match(kopf[0].textContent, /Grillen/);
    const slots = [...$("task-checks").querySelectorAll(".check.slot")];
    assert.equal(slots.length, 2);
    assert.match(slots[0].textContent, /9–10 Uhr belegt/);
    assert.ok(slots[0].querySelector("input").disabled);
    assert.match(slots[1].textContent, /10–11 Uhr 2 von 2 frei/);
    // Erklärung einmal an der Überschrift
    kopf[0].querySelector(".details").click();
    assert.ok(!$("info-g-grillen").classList.contains("hidden"));
    assert.equal($("task-checks").querySelectorAll(".aufgabe-info").length, 1);
    assert.deepEqual(s.fehler, []);
  }finally{ s.schliessen(); }
});

test("aufgabeName nennt bei Zeitfenstern die Zeit", async () => {
  const { s, w } = await editor();
  try{
    assert.equal(w.eval(`aufgabeName({ label:"Grillen", when:"9–10 Uhr", group:"grillen" })`), "Grillen (9–10 Uhr)");
    assert.equal(w.eval(`aufgabeName({ label:"Aufbau", when:"ab 12 Uhr" })`), "Aufbau");
  }finally{ s.schliessen(); }
});
