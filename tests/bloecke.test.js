// Bausteine im Editor: je Block ein Schalter "genutzt" und Auf- und Zuklappen.
// Aus ist nur ein leerer Block; mit Inhalt wird gefragt und geleert, mit Daten der
// Eltern oder Belegen bleibt er an. Vorlagen geben die Schalter an Veranstaltungen weiter.
const test = require("node:test");
const assert = require("node:assert/strict");
const { ladeSeite, warte } = require("./seite");

async function editor(){
  const s = ladeSeite("orga.html");
  const w = s.window, $ = id => w.document.getElementById(id);
  await s.geladen;
  $("key").value = "demo"; $("login").click();
  await warte(() => !$("view-list").classList.contains("hidden"), "Übersicht");
  const block = (name, ansicht = "#view-edit") =>
    w.document.querySelector(ansicht + ' fieldset[data-block="' + name + '"]');
  const schalten = (fs, an) => {
    const i = fs.querySelector(".schalter input");
    i.checked = an;
    i.dispatchEvent(new w.Event("change", { bubbles:true }));
  };
  return { s, w, $, block, schalten };
}

test("Leeren Block aus- und wieder einschalten", async () => {
  const { s, w, $, block, schalten } = await editor();
  try{
    await w.eval(`openEditor(events.find(e => e.id === "e-neu"))`);
    const spenden = block("spenden");
    assert.ok($("e-aus").classList.contains("hidden"), "anfangs ist alles an");
    let gefragt = false;
    w.confirm = () => { gefragt = true; return true; };
    schalten(spenden, false);
    assert.equal(gefragt, false, "leer: keine Rückfrage");
    assert.ok(spenden.classList.contains("aus"));
    assert.equal(spenden.parentNode.id, "e-aus", "steht unten");
    assert.ok(!$("e-aus").classList.contains("hidden"));
    assert.equal(spenden.querySelector(".schalter span").textContent, "nicht genutzt");
    assert.deepEqual({ ...w.eval("collectEvent().blocks") }, { spenden:false });
    schalten(spenden, true);
    assert.equal(spenden.previousSibling, spenden._platz, "wieder an alter Stelle");
    assert.ok($("e-aus").classList.contains("hidden"));
    assert.deepEqual({ ...w.eval("collectEvent().blocks") }, {});
    assert.deepEqual(s.fehler, []);
  }finally{ s.schliessen(); }
});

test("Block mit Inhalt: Rückfrage, dann geleert; Abbrechen lässt alles stehen", async () => {
  const { s, w, $, block, schalten } = await editor();
  try{
    await w.eval(`openEditor()`);
    $("add-check").click();
    $("checks").querySelector("input[type=text]").value = "Pavillon leihen";
    const liste = block("checkliste");
    w.confirm = () => false;
    schalten(liste, false);
    assert.ok(!liste.classList.contains("aus"), "abgebrochen");
    assert.equal($("checks").children.length, 1);
    w.confirm = text => { assert.match(text, /Planung — interne Checkliste/); return true; };
    schalten(liste, false);
    assert.ok(liste.classList.contains("aus"));
    assert.equal($("checks").children.length, 0, "geleert");
    // Kosten: Felder werden leer, nichts Verstecktes bleibt für die Anmeldeseite
    $("e-p-adults").value = "3,00";
    w.confirm = () => true;
    schalten(block("kosten"), false);
    assert.equal($("e-p-adults").value, "");
    assert.deepEqual({ ...w.eval("collectEvent().payment") }, {});
    assert.deepEqual(s.fehler, []);
  }finally{ s.schliessen(); }
});

test("Mit Daten der Eltern bleibt der Block an", async () => {
  const { s, w, $, block, schalten } = await editor();
  try{
    await w.eval(`openEditor(events.find(e => e.id === "e-neu"))`);
    assert.ok(w.eval("signups.some(x => (x.items || []).length)"), "Demodaten haben Mitbringsel");
    w.confirm = () => true;
    const kat = block("mitbringsel");
    schalten(kat, false);
    assert.ok(!kat.classList.contains("aus"));
    assert.ok($("cats").children.length > 0, "nichts gelöscht");
    assert.match($("edit-msg").textContent, /Mitbringsel eingetragen/);
    schalten(block("kosten"), false);
    assert.ok(!block("kosten").classList.contains("aus"), "Preise mit Anmeldungen bleiben");
    assert.deepEqual(s.fehler, []);
  }finally{ s.schliessen(); }
});

test("Zuklappen versteckt den Inhalt, Sprung aus den To-dos öffnet wieder", async () => {
  const { s, w, $, block, schalten } = await editor();
  try{
    await w.eval(`openEditor(events.find(e => e.id === "e-neu"))`);
    const einkauf = block("einkauf");
    const knopf = einkauf.querySelector(".klapp");
    assert.equal(knopf.textContent, "Einkaufsliste");
    knopf.click();
    assert.ok(einkauf.classList.contains("zu"));
    assert.equal(knopf.getAttribute("aria-expanded"), "false");
    assert.deepEqual([...w.eval("zuGemerkt()")], ["e:einkauf"]);
    w.eval(`blockOeffnen($("einkauf"))`);
    assert.ok(!einkauf.classList.contains("zu"));
    // ausgeschaltet und angesprungen: wieder an
    schalten(einkauf, false);
    assert.ok(einkauf.classList.contains("aus"));
    w.eval(`blockOeffnen($("einkauf"))`);
    assert.ok(!einkauf.classList.contains("aus"));
    assert.deepEqual(s.fehler, []);
  }finally{ s.schliessen(); }
});

test("Was in einen ausgeschalteten Block kommt, schaltet ihn ein", async () => {
  const { s, w, $, block, schalten } = await editor();
  try{
    await w.eval(`openEditor()`);
    const fragen = block("fragen");
    schalten(fragen, false);
    assert.ok(fragen.classList.contains("aus"));
    $("fields").appendChild(w.eval(`fieldRow({ label:"Allergien?", type:"text" })`));
    w.eval("markDirty()");
    assert.ok(!fragen.classList.contains("aus"));
    // gespeicherte Schalter mit Inhalt: der Inhalt gewinnt
    await w.eval(`openEditor({ ...events.find(e => e.id === "e-neu"), blocks:{ aufgaben:false, spenden:false } })`);
    assert.ok(!block("aufgaben").classList.contains("aus"));
    assert.ok(block("spenden").classList.contains("aus"));
    assert.deepEqual(s.fehler, []);
  }finally{ s.schliessen(); }
});

test("Vorlage gibt die Schalter an neue Veranstaltungen weiter", async () => {
  const { s, w, $, block, schalten } = await editor();
  try{
    w.eval(`openTemplate()`);
    $("t-name").value = "Laternenumzug";
    schalten(block("kosten", "#view-template"), false);
    schalten(block("einkauf", "#view-template"), false);
    $("t-b-spenden").checked = false;
    assert.equal(block("kosten", "#view-template").parentNode.id, "t-aus");
    $("t-save").click();
    await warte(() => w.eval(`templates.some(t => t.name === "Laternenumzug")`), "gespeichert");
    const tpl = w.eval(`templates.find(t => t.name === "Laternenumzug")`);
    assert.deepEqual({ ...tpl.blocks }, { kosten:false, einkauf:false, spenden:false });
    await w.eval(`handleTemplate("use", templates.find(t => t.name === "Laternenumzug").id)`);
    await warte(() => !$("view-edit").classList.contains("hidden"), "Editor");
    assert.ok(block("kosten").classList.contains("aus"));
    assert.ok(block("einkauf").classList.contains("aus"));
    assert.ok(block("spenden").classList.contains("aus"));
    assert.ok(!block("entscheidungen").classList.contains("aus"));
    assert.deepEqual({ ...w.eval("collectEvent().blocks") }, { kosten:false, einkauf:false, spenden:false });
    // Vorlage wieder öffnen: Schalter stehen wie gespeichert
    w.eval(`openTemplate(templates.find(t => t.name === "Laternenumzug"))`);
    assert.ok(block("kosten", "#view-template").classList.contains("aus"));
    assert.equal($("t-b-spenden").checked, false);
    assert.deepEqual(s.fehler, []);
  }finally{ s.schliessen(); }
});
