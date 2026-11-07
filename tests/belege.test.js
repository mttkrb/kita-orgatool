// Belege an der Einkaufsliste: nur fürs Orgateam, Foto plus Laden, Datum, Betrag, Posten.
// Die Rechte prüft tests/sql/rechte.sql gegen Postgres; hier der Nachbau und die Oberfläche.
const test = require("node:test");
const assert = require("node:assert/strict");
const { ladeSeite, warte } = require("./seite");
const { fakeDb, SUPABASE, ORGA } = require("./fake-db");

const BILD = "data:image/jpeg;base64,/9j/AAAA";

async function orga(){
  const s = ladeSeite("orga.html");
  const w = s.window, $ = id => w.document.getElementById(id);
  await s.geladen;
  $("key").value = "demo"; $("login").click();
  await warte(() => !$("view-list").classList.contains("hidden"), "Übersicht");
  return { s, w, $ };
}
const sichtbar = el => !el.classList.contains("hidden") && !el.closest(".hidden");
const foto = (w, el) => Object.defineProperty(el, "files",
  { configurable:true, value:[new w.File(["x"], "bon.jpg", { type:"image/jpeg" })] });

test("Beleg anhängen, ansehen, löschen", async () => {
  const { s, w, $ } = await orga();
  try{
    await w.eval(`(async () => {
      belegBild = async () => "${BILD}";
      demoPlanning["e-neu"] = { checklist:[], review:{},
        shopping:[{ id:"k1", menge:"19", einheit:"l", artikel:"Kinderpunsch", wer:"", preis:30, done:true }] };
      await openEditor(events.find(e => e.id === "e-neu"));
    })()`);
    await warte(() => sichtbar($("view-edit")), "Editor");
    assert.ok(sichtbar($("belege-box")));
    assert.match($("belege-box").textContent, /Kartennummer/);
    assert.match($("belege-box").textContent, /bleiben dauerhaft/);
    assert.ok([...$("b-posten").options].some(o => o.value === "k1" && /Kinderpunsch/.test(o.textContent)));

    $("b-dazu").click();
    await warte(() => /Foto/.test($("beleg-msg").textContent), "Hinweis ohne Foto");

    $("b-laden").value = "Getränkemarkt"; $("b-datum").value = "2026-11-10";
    $("b-betrag").value = "28,47"; $("b-posten").value = "k1";
    foto(w, $("b-foto"));
    $("b-dazu").click();
    await warte(() => $("belege").querySelectorAll(".beleg").length === 1, "Beleg in der Liste");
    const r = w.eval("demoReceipts[0]");
    assert.equal(r.event_id, "e-neu");
    assert.equal(r.shop, "Getränkemarkt");
    assert.equal(r.bought_on, "2026-11-10");
    assert.equal(r.amount, 28.47);
    assert.equal(r.item_id, "k1");
    assert.equal(r.image, BILD);
    const zeile = $("belege").querySelector(".beleg .was").textContent;
    assert.match(zeile, /Getränkemarkt/);
    assert.match(zeile, /10\.11\.2026/);
    assert.match(zeile, /für Kinderpunsch/);
    assert.match($("belege-summe").textContent, /1 Beleg, zusammen 28,47/);
    assert.match($("belege-summe").textContent, /Einkaufsliste sagt 30,00/);
    assert.equal($("b-laden").value, "", "Felder geleert");

    $("belege").querySelector(".beleg img").click();
    assert.ok(sichtbar($("beleg-gross")));
    assert.equal($("beleg-bild").getAttribute("src"), BILD);
    $("beleg-zu").click();
    assert.ok(!sichtbar($("beleg-gross")));

    $("belege").querySelector(".beleg button").click();
    await warte(() => !$("belege").querySelector(".beleg"), "Beleg gelöscht");
    assert.equal(w.eval("demoReceipts.length"), 0);
    assert.deepEqual(s.fehler, []);
  }finally{ s.schliessen(); }
});

test("Neue Veranstaltung: erst speichern, dann Belege", async () => {
  const { s, w, $ } = await orga();
  try{
    await w.eval("openEditor(null)");
    await warte(() => sichtbar($("view-edit")), "Editor");
    foto(w, $("b-foto"));
    $("b-dazu").click();
    await warte(() => /Erst speichern/.test($("beleg-msg").textContent), "Hinweis");
    assert.equal(w.eval("demoReceipts.length"), 0);
    assert.deepEqual(s.fehler, []);
  }finally{ s.schliessen(); }
});

test("Falscher Betrag wird nicht gespeichert", async () => {
  const { s, w, $ } = await orga();
  try{
    await w.eval(`(async () => { belegBild = async () => "${BILD}";
      await openEditor(events.find(e => e.id === "e-neu")); })()`);
    await warte(() => sichtbar($("view-edit")), "Editor");
    $("b-betrag").value = "zwölf"; foto(w, $("b-foto"));
    $("b-dazu").click();
    await warte(() => /Betrag/.test($("beleg-msg").textContent), "Hinweis Betrag");
    assert.equal(w.eval("demoReceipts.length"), 0);
  }finally{ s.schliessen(); }
});

test("Nach der Löschfrist: Belege bleiben an der archivierten Veranstaltung", async () => {
  const { s, w, $ } = await orga();
  try{
    await w.eval(`(async () => {
      demoSignups = demoSignups.filter(x => x.event !== "oma-opa-tag-2025");
      demoReceipts.push({ id:"r1", event_id:"e-alt", shop:"Metro", bought_on:"2025-10-30", amount:41.2,
        item_id:null, image:"${BILD}", created_at:"2025-10-30T10:00:00Z" });
      await openEditor(events.find(e => e.id === "e-alt"));
    })()`);
    await warte(() => sichtbar($("r-archiv")) && $("belege").querySelector(".beleg"), "Archivmodus mit Beleg");
    assert.match($("belege").textContent, /Metro · 30\.10\.2025 · 41,20/);
    assert.ok($("belege").querySelector(".beleg img"));
    assert.deepEqual(s.fehler, []);
  }finally{ s.schliessen(); }
});

test("Schnittstelle: Belege liest und schreibt nur das Orgateam", async () => {
  const db = fakeDb({ receipts:[{ id:"rc-0", event_id:"e1", image:BILD, amount:5 }] });
  const s = ladeSeite("orga.html", { supabase:SUPABASE, fetch:db.fetch });
  const w = s.window;
  try{
    await s.geladen;
    assert.equal(JSON.stringify(await w.eval("db.receipts('e1')")), "[]", "ohne Passwort nichts");
    await assert.rejects(w.eval(`db.addReceipt({ event_id:"e1", image:"${BILD}" })`));
    w.eval(`orgaKey = "${ORGA}"`);
    assert.equal((await w.eval("db.receipts('e1')")).length, 1);
    await w.eval(`db.addReceipt({ event_id:"e1", shop:"Aldi", amount:12.9, image:"${BILD}" })`);
    await assert.rejects(w.eval(`db.addReceipt({ event_id:"e1", image:"javascript:alert(1)" })`));
    assert.equal(db.receipts.length, 2);
    await w.eval("db.delReceipt('rc-0')");
    assert.deepEqual(db.receipts.map(r => r.shop), ["Aldi"]);
    const posten = db.anfragen.filter(a => a.url.includes("/receipts"));
    assert.ok(posten.every(a => !/token/.test(a.url)));
    assert.deepEqual(s.fehler, []);
  }finally{ s.schliessen(); }
});

test("Foto wird beim Auswählen gelesen; ist es nicht lesbar, Hinweis und neu auswählen", async () => {
  const { s, w, $ } = await orga();
  try{
    await w.eval(`(async () => { await openEditor(events.find(e => e.id === "e-neu")); })()`);
    await warte(() => sichtbar($("view-edit")), "Editor");
    // Erst schlägt das Lesen fehl, wie auf Android nach abgelaufenem Zugriff
    w.eval(`belegBild = async () => { throw new Error("Foto nicht lesbar"); }`);
    foto(w, $("b-foto"));
    $("b-foto").dispatchEvent(new w.Event("change"));
    await warte(() => /noch einmal auswählen/.test($("beleg-msg").textContent), "Hinweis");
    assert.equal(w.eval("belegFoto"), null);
    assert.equal(w.eval("demoReceipts.length"), 0);

    // Neu ausgewählt: wird sofort vorbereitet und beim Hinzufügen verwendet
    let gelesen = 0;
    w.belegBild = async () => { gelesen++; return BILD; };
    w.eval(`belegBild = window.belegBild`);
    foto(w, $("b-foto"));
    $("b-foto").dispatchEvent(new w.Event("change"));
    await warte(() => /Foto bereit/.test($("beleg-msg").textContent), "bereit");
    $("b-betrag").value = "29,80";
    $("b-dazu").click();
    await warte(() => w.eval("demoReceipts.length") === 1, "gespeichert");
    assert.equal(gelesen, 1, "nur einmal gelesen, beim Auswählen");
    assert.equal(w.eval("demoReceipts[0].amount"), 29.8);
    assert.deepEqual(s.fehler, []);
  }finally{ s.schliessen(); }
});

test("Posten-Auswahl nur, wenn die Einkaufsliste Posten hat", async () => {
  const { s, w, $ } = await orga();
  try{
    await w.eval(`(async () => {
      demoPlanning["e-neu"].shopping = [];
      await openEditor(events.find(e => e.id === "e-neu"));
    })()`);
    await warte(() => sichtbar($("view-edit")), "Editor");
    assert.ok(!sichtbar($("b-posten-box")), "leere Einkaufsliste: kein Feld");
    $("add-kauf").click();
    const art = $("einkauf").lastElementChild.querySelector(".k-artikel");
    art.value = "Glühwein";
    art.dispatchEvent(new w.Event("input", { bubbles:true }));
    assert.ok(sichtbar($("b-posten-box")), "erscheint beim Tippen");
    assert.ok([...$("b-posten").options].some(o => /Glühwein/.test(o.textContent)));
    assert.deepEqual(s.fehler, []);
  }finally{ s.schliessen(); }
});

test("Ausgabe ohne Beleg: nur mit Betrag, zählt im Kassensturz", async () => {
  const { s, w, $ } = await orga();
  try{
    await w.eval(`openEditor(events.find(e => e.id === "e-neu"))`);
    await warte(() => sichtbar($("view-edit")), "Editor");
    $("b-laden").value = "Wochenmarkt";
    $("b-dazu").click();
    await warte(() => /Betrag eintragen/.test($("beleg-msg").textContent), "Betrag fehlt");
    assert.equal(w.eval("demoReceipts.length"), 0);
    $("b-betrag").value = "7,50";
    $("b-dazu").click();
    await warte(() => w.eval("demoReceipts.length") === 1, "gespeichert");
    assert.equal(w.eval("demoReceipts[0].image"), null);
    assert.equal(w.eval("demoReceipts[0].amount"), 7.5);
    await warte(() => $("belege").querySelector(".beleg-ohne"), "Liste");
    assert.match($("belege").textContent, /ohne Beleg.*Wochenmarkt · 7,50/);
    assert.match($("kasse").textContent.replace(/\s/g, " "), /laut Belegen7,50/);
    assert.deepEqual(s.fehler, []);
  }finally{ s.schliessen(); }
});

test("PDF als Beleg: unverändert gespeichert, in der Liste zum Herunterladen", async () => {
  const { s, w, $ } = await orga();
  try{
    await w.eval(`openEditor(events.find(e => e.id === "e-neu"))`);
    await warte(() => sichtbar($("view-edit")), "Editor");
    const pdf = new w.File(["%PDF-1.4 Rechnung"], "rechnung.pdf", { type:"application/pdf" });
    Object.defineProperty($("b-foto"), "files", { configurable:true, value:[pdf] });
    $("b-foto").dispatchEvent(new w.Event("change"));
    await warte(() => /PDF bereit/.test($("beleg-msg").textContent), "PDF bereit");
    $("b-laden").value = "Onlineshop"; $("b-betrag").value = "19,99";
    $("b-dazu").click();
    await warte(() => w.eval("demoReceipts.length") === 1, "gespeichert");
    const bild = w.eval("demoReceipts[0].image");
    assert.match(bild, /^data:application\/pdf;base64,/);
    assert.equal(Buffer.from(bild.split(",")[1], "base64").toString(), "%PDF-1.4 Rechnung");
    await warte(() => $("belege").querySelector(".beleg-pdf"), "PDF in der Liste");
    assert.ok(!$("belege").querySelector("img"), "kein Bild");
    // Herunterladen erzeugt einen Link mit Dateinamen
    let datei = "";
    w.URL.createObjectURL = () => "blob:test";
    w.URL.revokeObjectURL = () => {};
    w.HTMLAnchorElement.prototype.click = function(){ datei = this.download; };
    $("belege").querySelector(".beleg-pdf").click();
    assert.equal(datei, "beleg-onlineshop.pdf");
    assert.deepEqual(s.fehler, []);
  }finally{ s.schliessen(); }
});

test("PDF über 1 MB wird abgelehnt", async () => {
  const { s, w, $ } = await orga();
  try{
    await w.eval(`openEditor(events.find(e => e.id === "e-neu"))`);
    await warte(() => sichtbar($("view-edit")), "Editor");
    const gross = new w.File([new Uint8Array(1200000)], "gross.pdf", { type:"application/pdf" });
    Object.defineProperty($("b-foto"), "files", { configurable:true, value:[gross] });
    $("b-foto").dispatchEvent(new w.Event("change"));
    await warte(() => /PDF zu groß/.test($("beleg-msg").textContent), "zu groß");
    assert.equal($("b-foto").value, "");
  }finally{ s.schliessen(); }
});

test("Nachbau: ohne Beleg nur mit Betrag, PDF ja, HTML nein", async () => {
  const db = fakeDb();
  const s = ladeSeite("orga.html", { supabase:SUPABASE, fetch:db.fetch });
  const w = s.window;
  try{
    await s.geladen;
    w.eval(`orgaKey = "${ORGA}"`);
    await w.eval(`db.addReceipt({ event_id:"e1", amount:3 })`);
    await w.eval(`db.addReceipt({ event_id:"e1", amount:9, image:"data:application/pdf;base64,JVBERi0x" })`);
    await assert.rejects(w.eval(`db.addReceipt({ event_id:"e1", shop:"leer" })`));
    await assert.rejects(w.eval(`db.addReceipt({ event_id:"e1", amount:1, image:"data:text/html;base64,PGI+" })`));
    assert.equal(db.receipts.length, 2);
  }finally{ s.schliessen(); }
});
