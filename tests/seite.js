// Lädt eine Seite des Tools in jsdom, wie sie auf dem Webspace unter /orga/ liegt.
// config.js wird für jeden Test neu erzeugt, alles andere kommt aus dem Repo.
// Fehler der Seite (auch SyntaxError beim Laden) landen in `fehler`.
const fs = require("fs");
const path = require("path");
const { afterEach } = require("node:test");
const { JSDOM, ResourceLoader, VirtualConsole } = require("jsdom");

const REPO = path.join(__dirname, "..");
const BASIS = "https://kita.test/orga/";

// Fenster nach jedem Test schließen, auch wenn er scheitert. Sonst hält der
// Aktualisierungs-Timer der Seiten den Testlauf am Leben.
const offen = [];
afterEach(() => { while(offen.length) offen.pop().close(); });

class Dateien extends ResourceLoader {
  constructor(config){ super(); this.config = config; }
  fetch(url, options){
    if(!url.startsWith(BASIS)) return Promise.reject(new Error("Fremdquelle geladen: " + url));
    const datei = new URL(url).pathname.slice("/orga/".length);
    if(datei === "config.js") return Promise.resolve(Buffer.from(this.config));
    return Promise.resolve(fs.readFileSync(path.join(REPO, datei)));
  }
}

// supabase: { url, anonKey } oder leer für Demo-Modus
// settings: Objekt für SETTINGS, null = ältere config.js ohne SETTINGS
// fetch: Ersatz für window.fetch; ohne Angabe ist jede Anfrage ein Fehler
function ladeHtml(html, { seite = "test.html", query = "", supabase = {}, settings = {}, fetch } = {}){
  const fehler = [];
  const konsole = new VirtualConsole();
  konsole.on("jsdomError", e => fehler.push(e.message + (e.detail ? " " + e.detail : "")));
  konsole.on("error", (...a) => fehler.push(a.join(" ")));
  const config = "const SUPABASE = " + JSON.stringify({ url:"", anonKey:"", ...supabase }) + ";\n" +
    (settings === null ? "" : "const SETTINGS = " + JSON.stringify(settings) + ";\n");
  const dom = new JSDOM(html, {
    url: BASIS + seite + query,
    runScripts: "dangerously",
    resources: new Dateien(config),
    pretendToBeVisual: true,
    virtualConsole: konsole,
    beforeParse(w){
      w.fetch = fetch || (async u => { throw new Error("Unerwartete Anfrage: " + u); });
      w.Element.prototype.scrollIntoView = () => {};
      w.scrollTo = () => {};
      w.confirm = () => true;
    }
  });
  const window = dom.window;
  offen.push(window);
  const geladen = new Promise(ok => window.addEventListener("load", ok));
  return { window, fehler, geladen, schliessen: () => window.close() };
}

const ladeSeite = (datei, optionen = {}) =>
  ladeHtml(fs.readFileSync(path.join(REPO, datei), "utf8"), { ...optionen, seite: datei });

// Wartet, bis bedingung() wahr ist; sonst Fehler mit Beschreibung.
async function warte(bedingung, was = "Bedingung", ms = 3000){
  const ende = Date.now() + ms;
  while(Date.now() < ende){
    if(bedingung()) return;
    await new Promise(r => setTimeout(r, 10));
  }
  throw new Error("Zeitüberschreitung: " + was);
}

module.exports = { ladeHtml, ladeSeite, warte, BASIS };
