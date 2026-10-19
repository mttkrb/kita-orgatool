// Jede Seite lädt im Demo-Modus ohne Fehler und ohne Anfragen nach außen.
// Fängt vor allem neu deklarierte Namen aus common.js ab: das ist ein SyntaxError,
// und die ganze Seite bleibt stehen.
const test = require("node:test");
const assert = require("node:assert/strict");
const { ladeSeite } = require("./seite");

const SEITEN = ["index.html", "fest-anmeldung.html", "orga.html", "vorschlag.html", "feedback.html"];

for(const datei of SEITEN){
  for(const [wie, settings] of [["mit SETTINGS", { name:"Kita Sonne" }], ["ältere config.js", null]]){
    test(datei + " lädt im Demo-Modus, " + wie, async () => {
      const s = ladeSeite(datei, { settings });
      await s.geladen;
      await new Promise(r => setTimeout(r, 100));
      try{
        assert.deepEqual(s.fehler, []);
        assert.equal(s.window.eval("live"), false);
        if(settings) assert.match(s.window.document.title, /Kita Sonne$/);
      }finally{ s.schliessen(); }
    });
  }
}
