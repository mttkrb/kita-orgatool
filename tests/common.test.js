// Hilfsfunktionen aus common.js, geladen wie in den Seiten.
const test = require("node:test");
const assert = require("node:assert/strict");
const { ladeHtml } = require("./seite");

const SEITE = '<!DOCTYPE html><html><head><title>Test</title>' +
  '<script src="config.js"></script><script src="common.js"></script></head>' +
  '<body><div class="wrap"><header>Kopf</header></div></body></html>';

async function common(optionen){
  const s = ladeHtml(SEITE, optionen);
  await s.geladen;
  // const auf oberster Ebene hängt nicht an window, daher über eval
  s.g = name => s.window.eval(name);
  return s;
}

test("esc entschärft HTML", async () => {
  const s = await common();
  assert.equal(s.g("esc")('<img src=x onerror="a">&\''), "&lt;img src=x onerror=&quot;a&quot;&gt;&amp;&#39;");
  assert.equal(s.g("esc")(null), "");
  assert.deepEqual(s.fehler, []);
});

test("bildUrl lässt nur eingebettete Bilder durch", async () => {
  const s = await common();
  const bildUrl = s.g("bildUrl");
  assert.equal(bildUrl("data:image/jpeg;base64,AAAA"), "data:image/jpeg;base64,AAAA");
  assert.equal(bildUrl("https://fremd.example/bild.jpg"), "");
  assert.equal(bildUrl("data:image/svg+xml;base64,AAAA"), "");
});

test("SIGNUP_COLS enthält kein token", async () => {
  const s = await common();
  assert.ok(!s.g("SIGNUP_COLS").split(",").includes("token"));
});

test("isoDatum rechnet in Ortszeit, nicht in UTC", async () => {
  const s = await common();
  // Kurz nach Mitternacht in Berlin ist in UTC noch der Vortag
  const d = new s.window.Date(2026, 9, 19, 0, 30);
  assert.equal(s.g("isoDatum")(d), "2026-10-19");
});

const EV = {
  ask_people: true,
  payment: { adults:"5,00", kids:"2.5" },
  fields: [
    { type:"order", label:"Laterne", price:"3,50", max:2 },
    { type:"order", label:"Brezel", price:1 },
    { type:"text", label:"Allergien" }
  ]
};

test("kosten rechnet Personen und Bestellungen, kappt auf max", async () => {
  const s = await common();
  const k = s.g("kosten")(EV, { adults:2, kids:1, fields:{ Laterne:5, Brezel:"3" } });
  // 2×5 + 1×2,50 + 2×3,50 (gekappt) + 3×1
  assert.equal(k.summe, 22.5);
  assert.deepEqual([...k.zeilen.map(z=>z.label)], ["Erwachsene", "Kinder", "Laterne", "Brezel"]);
});

test("Bestellartikel ohne max kappen bei 99", async () => {
  const s = await common();
  assert.equal(s.g("bestellMenge")({ fields:{ Brezel:500 } }, { label:"Brezel" }), 99);
  assert.equal(s.g("bestellMenge")({ fields:{ Brezel:-3 } }, { label:"Brezel" }), 0);
});

test("Absagen kosten nichts", async () => {
  const s = await common();
  assert.equal(s.g("kosten")(EV, { adults:2, kids:1, status:"absage" }).summe, 0);
});

test("ausgeschaltete Gruppen kosten nichts", async () => {
  const s = await common();
  const ev = { ...EV, fields:[], people:{ adults:{ on:true }, kids:{ on:false } } };
  assert.equal(s.g("kosten")(ev, { adults:1, kids:3 }).summe, 5);
  assert.equal(s.g("kostetEtwas")({ payment:{ adults:"0" } }), false);
});

test("preisZahl und euro", async () => {
  const s = await common();
  assert.equal(s.g("preisZahl")("3,50"), 3.5);
  assert.equal(s.g("preisZahl")("-1"), 0);
  assert.equal(s.g("preisZahl")("abc"), 0);
  assert.equal(s.g("euro")(3.5), "3,50\u00a0€");
});

test("zahlweg liest link und das ältere paypal", async () => {
  const s = await common();
  const zahlweg = s.g("zahlweg");
  assert.deepEqual({ ...zahlweg({ paypal:"kitasonne" }) }, { art:"paypalme", wert:"kitasonne" });
  assert.deepEqual({ ...zahlweg({ link:"https://paypal.me/kitasonne" }) }, { art:"paypalme", wert:"kitasonne" });
  assert.deepEqual({ ...zahlweg({ link:"kasse@kita.de" }) }, { art:"mail", wert:"kasse@kita.de" });
  assert.deepEqual({ ...zahlweg({ link:"https://wero.example/pay/1" }) },
    { art:"link", wert:"https://wero.example/pay/1" });
  assert.equal(zahlweg({ link:"http://unsicher.example/" }), null);
  assert.equal(zahlweg({ link:"javascript:alert(1)" }), null);
  assert.equal(zahlweg({}), null);
});

test("paypalLink mit Betrag", async () => {
  const s = await common();
  assert.equal(s.g("paypalLink")("kitasonne", 12.5), "https://www.paypal.me/kitasonne/12.50EUR");
  assert.equal(s.g("paypalLink")("kein name!", 1), "");
});

test("textMitFormat: Auszeichnungen, Absätze, kein HTML", async () => {
  const s = await common();
  const d = s.window.document;
  const ziel = d.createElement("div");
  s.g("textMitFormat")(ziel, "*Ablauf*\nab _14 Uhr_ ~nicht~\n\nkita_sonne 3*4 <b>x</b>");
  const [p1, p2] = ziel.querySelectorAll("p");
  assert.equal(p1.querySelector("strong").textContent, "Ablauf");
  assert.equal(p1.querySelector("em").textContent, "14 Uhr");
  assert.equal(p1.querySelector("s").textContent, "nicht");
  assert.equal(p1.querySelectorAll("br").length, 1);
  assert.equal(p2.textContent, "kita_sonne 3*4 <b>x</b>");
  assert.equal(p2.children.length, 0);
});

test("eigeneAdresse lässt nur die eigene Domain zu", async () => {
  const s = await common();
  const eigeneAdresse = s.g("eigeneAdresse");
  assert.equal(eigeneAdresse("icons/logo.svg"), "https://kita.test/orga/icons/logo.svg");
  assert.equal(eigeneAdresse("https://fremd.example/logo.png"), "");
  assert.equal(eigeneAdresse("//fremd.example/logo.png"), "");
});

test("SETTINGS: Name im Titel und Kopf, eigene Farbe, fremdes Logo ignoriert", async () => {
  const s = await common({ settings:{ name:"Kita Sonne", logo:"https://fremd.example/l.png",
    colors:{ main:"#123456", accent:"rot" } } });
  const d = s.window.document;
  assert.equal(d.title, "Test · Kita Sonne");
  assert.equal(d.querySelector(".marke span").textContent, "Kita Sonne");
  assert.equal(d.querySelector(".marke img"), null);
  assert.equal(d.documentElement.style.getPropertyValue("--moss"), "#123456");
  assert.equal(d.documentElement.style.getPropertyValue("--berry"), "");
  assert.deepEqual(s.fehler, []);
});

test("ältere config.js ohne SETTINGS funktioniert", async () => {
  const s = await common({ settings:null });
  assert.equal(s.window.document.title, "Test");
  assert.equal(s.g("kitaName"), "");
  assert.deepEqual(s.fehler, []);
});
