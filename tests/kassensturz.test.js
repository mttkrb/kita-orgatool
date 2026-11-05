// Kassensturz oben im Editor: Einnahmen Soll gegen Zahlungseingang, Ausgaben laut
// Einkaufsliste gegen Belege, jeweils mit Delta und Saldo.
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
const zeilen = $ => [...$("kasse").querySelectorAll("tr")].map(tr =>
  [...tr.children].map(td => td.textContent.replace(/\s/g, " ")));

test("Kassensturz: Soll, Ist und Delta für Einnahmen und Ausgaben", async () => {
  const { s, w, $ } = await editor("e-neu",
    `demoReceipts.push({ id:"r1", event_id:"e-neu", shop:"Markt", amount:30, image:"data:image/jpeg;base64,AA", created_at:"" },
                       { id:"r2", event_id:"e-neu", shop:"Bäcker", amount:null, image:"data:image/jpeg;base64,AA", created_at:"" })`);
  try{
    await warte(() => /30,00/.test($("kasse").textContent), "Kassensturz mit Belegen");
    const t = zeilen($);
    // Soll: Tim 2×3 + 1×5 + 3×2,50 = 18,50; Anne 1×3 + 2×5 = 13,00. Bezahlt: Tim 18,50.
    assert.deepEqual(t[1], ["Einnahmen", "31,50 €", "18,50 €", "−13,00 €"]);
    // Einkaufsliste 32,00 + 12,90; Belege mit Betrag 30,00
    assert.deepEqual(t[2], ["Ausgaben", "44,90 €", "30,00 €", "−14,90 €"]);
    assert.deepEqual(t[3], ["Saldo", "−13,40 €", "−11,50 €", "+1,90 €"]);
    assert.ok($("kasse").querySelector("tr:nth-child(2) .minus"), "offene Einnahmen rot");
    assert.match($("kasse").textContent, /1 Beleg hat noch keinen Betrag/);
    assert.ok($("kasse").compareDocumentPosition($("history")) & w.Node.DOCUMENT_POSITION_FOLLOWING,
      "steht oben im Editor");

    // Preis in der Einkaufsliste ändern rechnet sofort neu
    const preis = $("einkauf").querySelector(".k-preis");
    preis.value = "40"; preis.dispatchEvent(new w.Event("input", { bubbles:true }));
    assert.deepEqual(zeilen($)[2], ["Ausgaben", "52,90 €", "30,00 €", "−22,90 €"]);
    assert.deepEqual(s.fehler, []);
  }finally{ s.schliessen(); }
});

test("Mehr ausgegeben als geplant ist rot", async () => {
  const { s, $ } = await editor("e-neu",
    `demoReceipts.push({ id:"r1", event_id:"e-neu", amount:50, image:"data:image/jpeg;base64,AA", created_at:"" })`);
  try{
    await warte(() => /50,00/.test($("kasse").textContent), "Beleg");
    assert.deepEqual(zeilen($)[2], ["Ausgaben", "44,90 €", "50,00 €", "+5,10 €"]);
    assert.ok($("kasse").querySelector("tr:nth-child(3) .minus"));
  }finally{ s.schliessen(); }
});

test("Ohne Geld kein Kassensturz", async () => {
  const { s, $ } = await editor("");   // neue Veranstaltung
  try{
    assert.ok($("kasse").classList.contains("hidden"));
    assert.deepEqual(s.fehler, []);
  }finally{ s.schliessen(); }
});
