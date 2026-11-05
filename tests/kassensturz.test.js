// Kassensturz oben im Editor: Einnahmen geplant (was die Anmeldungen kosten), bezahlt und
// offen; Ausgaben laut Belegen; darunter der Kassenstand.
const test = require("node:test");
const assert = require("node:assert/strict");
const { ladeSeite, warte } = require("./seite");

async function editor(id, vorher = ""){
  const s = ladeSeite("orga.html");
  const w = s.window, $ = x => w.document.getElementById(x);
  await s.geladen;
  $("key").value = "demo"; $("login").click();
  await warte(() => !$("view-list").classList.contains("hidden"), "Übersicht");
  await w.eval(`(async () => { ${vorher}; await openEditor(events.find(e => e.id === "${id}") || null); })()`);
  await warte(() => !$("view-edit").classList.contains("hidden"), "Editor");
  return { s, w, $ };
}
const text = el => el.textContent.replace(/\s/g, " ");
const zeilen = $ => [...$("kasse").querySelectorAll("tr")].map(tr => [...tr.children].map(text));
const BILD = "data:image/jpeg;base64,AA";

test("Kassensturz: Einnahmen geplant, bezahlt, offen; Ausgaben laut Belegen", async () => {
  const { s, w, $ } = await editor("e-neu",
    `demoReceipts.push({ id:"r1", event_id:"e-neu", shop:"Markt", amount:30, image:"${BILD}", created_at:"" },
                       { id:"r2", event_id:"e-neu", shop:"Bäcker", amount:null, image:"${BILD}", created_at:"" })`);
  try{
    await warte(() => /30,00/.test($("kasse").textContent), "Kassensturz mit Belegen");
    const t = zeilen($);
    assert.equal(t.length, 2, "zwei Zeilen");
    // Soll: Tim 2×3 + 1×5 + 3×2,50 = 18,50; Anne 1×3 + 2×5 = 13,00. Bezahlt: Tim 18,50.
    assert.deepEqual(t[0], ["Einnahmen", "geplant31,50 €", "bezahlt18,50 €", "offen13,00 €"]);
    assert.deepEqual(t[1], ["Ausgaben", "laut Belegen30,00 €", "", ""]);
    assert.ok($("kasse").querySelector("tr:first-child .minus"), "offene Einnahmen rot");
    assert.match(text($("kasse").querySelector(".stand")), /Kassenstand: −11,50 €/);
    assert.match($("kasse").textContent, /1 Beleg hat noch keinen Betrag/);
    assert.match($("kasse").textContent, /Die Einkaufsliste plant 44,90/, "Plan nur als Hinweis");
    assert.ok($("kasse").compareDocumentPosition($("history")) & w.Node.DOCUMENT_POSITION_FOLLOWING,
      "steht oben im Editor");

    // Beim Speichern werden die Belege als Ausgaben festgehalten, nicht die Einkaufsliste
    $("save").click();
    await warte(() => /Gespeichert/.test($("edit-msg").textContent), "Speichern");
    assert.equal(w.eval("planning.review.geld.ausgaben"), 30);
    assert.deepEqual(s.fehler, []);
  }finally{ s.schliessen(); }
});

test("Ohne Preise in der Einkaufsliste zählen trotzdem die Belege", async () => {
  const { s, w, $ } = await editor("e-neu",
    `demoPlanning["e-neu"].shopping.forEach(p => delete p.preis);
     demoReceipts.push({ id:"r1", event_id:"e-neu", amount:50, image:"${BILD}", created_at:"" })`);
  try{
    await warte(() => /50,00/.test($("kasse").textContent), "Beleg");
    assert.deepEqual(zeilen($)[1], ["Ausgaben", "laut Belegen50,00 €", "", ""]);
    assert.match(text($("kasse").querySelector(".stand")), /Kassenstand: −31,50 €/);
    assert.doesNotMatch($("kasse").textContent, /Einkaufsliste plant/);
  }finally{ s.schliessen(); }
});

test("Noch kein Beleg: Ausgaben –, Kassenstand ist das Bezahlte", async () => {
  const { s, $ } = await editor("e-neu");
  try{
    assert.deepEqual(zeilen($)[1], ["Ausgaben", "laut Belegen–", "", ""]);
    assert.match(text($("kasse").querySelector(".stand")), /Kassenstand: 18,50 €/);
  }finally{ s.schliessen(); }
});

test("Ohne Geld kein Kassensturz", async () => {
  const { s, $ } = await editor("");   // neue Veranstaltung
  try{
    assert.ok($("kasse").classList.contains("hidden"));
    assert.deepEqual(s.fehler, []);
  }finally{ s.schliessen(); }
});
