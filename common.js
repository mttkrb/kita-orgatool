// Gemeinsame Hilfsfunktionen aller Seiten.
// Wird nach config.js und vor dem Skript der Seite geladen, im <head>.

const live = !!(SUPABASE.url && SUPABASE.anonKey);
const $ = id => document.getElementById(id);

// Fremde Eingaben vor dem Einsetzen in HTML entschärfen.
const esc = s => String(s??"").replace(/[<>&"']/g,c=>({"<":"&lt;",">":"&gt;","&":"&amp;",'"':"&quot;","'":"&#39;"}[c]));
// Nur eingebettete Bilder durchlassen, keine fremden Adressen.
const bildUrl = s => /^data:image\/(jpeg|png|webp|gif);base64,[A-Za-z0-9+\/=]+$/.test(String(s||"")) ? s : "";

// Lesbare Spalten der Anmeldungen, ohne token (dafür fehlt anon das Leserecht).
// Überall dieselbe Liste, damit Export und Sicherung nichts verlieren.
const SIGNUP_COLS = "id,event,created_at,name,adults,kids,items,tasks,fields,note,status";

// Kopfzeilen für die REST-API mit dem anonKey, extra ergänzt oder überschreibt.
const anonHead = extra => Object.assign({
  apikey: SUPABASE.anonKey,
  Authorization: "Bearer " + SUPABASE.anonKey
}, extra||{});

// Datum als JJJJ-MM-TT in Ortszeit. Nicht toISOString nehmen: das rechnet in UTC
// und liefert zwischen Mitternacht und 1 bzw. 2 Uhr noch den Vortag.
const isoDatum = d => d.getFullYear() + "-" + String(d.getMonth()+1).padStart(2,"0") +
  "-" + String(d.getDate()).padStart(2,"0");
const heute = () => isoDatum(new Date());

const fmtDate = iso => {
  if(!iso) return "";
  const d = new Date(iso + "T12:00:00");
  if(isNaN(d)) return "";
  return d.toLocaleDateString("de-DE", { weekday:"long", day:"numeric", month:"long", year:"numeric" });
};

// Was die Eltern von den Anmeldungen sehen dürfen, Standard: alles.
const vis = ev => {
  const v = (ev && ev.visibility) || {};
  const on = k => v[k] !== false;
  return { totals:on("totals"), items:on("items"), itemNames:on("itemNames"), taskNames:on("taskNames") };
};

// Personengruppen der Anmeldung mit Bezeichnung und Höchstzahl.
const groups = ev => {
  const p = (ev && ev.people) || {};
  const on = (ev && ev.ask_people) !== false;
  return {
    adults: { on: p.adults ? !!p.adults.on : on, label: (p.adults && p.adults.label) || "Erwachsene",
              max: (p.adults && +p.adults.max) || 6 },
    kids:   { on: p.kids   ? !!p.kids.on   : on, label: (p.kids   && p.kids.label)   || "Kinder",
              max: (p.kids   && +p.kids.max)   || 6 }
  };
};

/* ---------- Kosten ---------- */
// Betrag als "3,50 €".
const euro = n => (Math.round((+n||0)*100)/100).toLocaleString("de-DE",
  { minimumFractionDigits:2, maximumFractionDigits:2 }) + " €";

// Preis aus einer Eingabe wie "3,50" oder einer Zahl. Leer, negativ oder Unsinn = 0.
const preisZahl = v => {
  const n = parseFloat(String(v ?? "").replace(",", "."));
  return isFinite(n) && n > 0 ? Math.round(n*100)/100 : 0;
};

// Bestellartikel mit Stückpreis sind Zusatzfragen vom Typ "order".
const bestellArtikel = ev => ((ev && ev.fields) || []).filter(f=>f.type === "order");
// Die Höchstmenge gilt nur hier im Browser; die Datenbank begrenzt Antworten nicht.
// Wer über die API mehr einträgt, wird beim Rechnen auf max gekappt, damit der
// Soll-Betrag im Orga-Bereich nicht ausufert.
const bestellMenge = (e, f) => Math.min(+f.max || 99,
  Math.max(0, Math.floor(+(((e && e.fields) || {})[f.label]) || 0)));

// Kostet die Veranstaltung überhaupt etwas?
const kostetEtwas = ev => {
  const p = (ev && ev.payment) || {};
  const g = groups(ev);
  return (g.adults.on && preisZahl(p.adults) > 0) || (g.kids.on && preisZahl(p.kids) > 0) ||
    bestellArtikel(ev).some(f=>preisZahl(f.price) > 0);
};

// Was eine Anmeldung kostet: Personen beider Gruppen plus Bestellungen.
// Der Betrag wird nie gespeichert, sondern immer hieraus gerechnet. Absagen kosten nichts.
const kosten = (ev, e) => {
  const p = (ev && ev.payment) || {};
  const g = groups(ev);
  const zeilen = [];
  if(!e || e.status === "absage") return { zeilen, summe:0 };
  const dazu = (label, menge, preis) => {
    if(menge > 0 && preis > 0) zeilen.push({ label, menge, preis, summe:Math.round(menge*preis*100)/100 });
  };
  if(g.adults.on) dazu(g.adults.label, +e.adults || 0, preisZahl(p.adults));
  if(g.kids.on)   dazu(g.kids.label,   +e.kids   || 0, preisZahl(p.kids));
  bestellArtikel(ev).forEach(f=>dazu(f.label, bestellMenge(e, f), preisZahl(f.price)));
  return { zeilen, summe:Math.round(zeilen.reduce((a,z)=>a+z.summe, 0)*100)/100 };
};

// Name bei PayPal.me, auch wenn jemand den ganzen PayPal.me-Link einträgt.
// Andere Adressen mit Schrägstrich oder Doppelpunkt sind kein Name.
const paypalName = s => {
  let n = String(s || "").trim();
  const m = n.match(/^(?:https?:\/\/)?(?:www\.)?paypal\.(?:me|com\/paypalme)\/([^\/?#]+)/i);
  if(m) n = m[1]; else if(/[\/:]/.test(n)) return "";
  return /^[A-Za-z0-9._-]{1,40}$/.test(n) ? n : "";
};
// PayPal-Adresse (E-Mail), an die Eltern über Freunde & Familie senden.
// Dafür gibt es keinen Link mit Betrag; die Seite zeigt Adresse und Betrag zum Kopieren.
const paypalMail = s => {
  const m = String(s || "").trim();
  return /^[^\s@<>"']{1,64}@[^\s@<>"']{1,190}\.[A-Za-z]{2,}$/.test(m) ? m : "";
};
// Link zu PayPal.me mit Betrag. Nur ein Link: die Seite selbst lädt nichts von PayPal.
const paypalLink = (name, betrag) => {
  const n = paypalName(name);
  if(!n) return "";
  return "https://www.paypal.me/" + encodeURIComponent(n) + (betrag > 0 ? "/" + betrag.toFixed(2) + "EUR" : "");
};

// Beliebiger Zahllink, etwa von Wero oder der Bank. Nur https, nur ein Link: die Seite
// lädt nichts von dort, die Eltern öffnen ihn selbst.
const zahlLink = s => {
  const t = String(s || "").trim();
  if(t.length > 300) return "";
  try{ const u = new URL(t); return u.protocol === "https:" ? u.href : ""; }catch(e){ return ""; }
};
// Zahlweg einer Veranstaltung aus payment.link (früher payment.paypal):
// PayPal-Adresse, PayPal.me-Name oder anderer Zahllink. Sonst null.
const zahlweg = p => {
  const roh = (p && (p.link || p.paypal)) || "";
  const mail = paypalMail(roh);
  if(mail) return { art:"mail", wert:mail };
  const name = paypalName(roh);
  if(name) return { art:"paypalme", wert:name };
  const url = zahlLink(roh);
  return url ? { art:"link", wert:url } : null;
};

// Text des Orgateams mit Absätzen und einfachen Auszeichnungen wie in WhatsApp:
// *fett*, _kursiv_, ~durchgestrichen~. Leerzeile = neuer Absatz, Zeilenumbruch bleibt.
// Baut die Elemente selbst und setzt nur textContent, nie innerHTML (fremde Eingabe).
function textMitFormat(ziel, text){
  ziel.replaceChildren();
  const ARTEN = { "*":"strong", "_":"em", "~":"s" };
  const wortzeichen = c => !!c && /[0-9A-Za-zÀ-ÖØ-öø-ÿ]/.test(c);
  const zeile = (p, t) => {
    // **fett** wie in Markdown gilt auch
    t = t.replace(/\*\*(?=\S)([^\n]*?\S)\*\*/g, "*$1*");
    // Marker zählen nur an Wortgrenzen, damit kita_sonne oder 3*4 Text bleiben
    const re = /([*_~])([^\s*_~](?:[^\n]*?[^\s])?)\1/g;
    let pos = 0, m;
    while((m = re.exec(t))){
      if(wortzeichen(t[m.index - 1]) || wortzeichen(t[m.index + m[0].length])){
        re.lastIndex = m.index + 1; continue;
      }
      if(m.index > pos) p.append(t.slice(pos, m.index));
      const el = document.createElement(ARTEN[m[1]]);
      el.textContent = m[2];
      p.append(el);
      pos = m.index + m[0].length;
    }
    if(pos < t.length) p.append(t.slice(pos));
  };
  const rein = String(text || "").replace(/\r\n?/g, "\n").trim();
  if(!rein) return;
  rein.split(/\n\s*\n/).forEach(absatz=>{
    const p = document.createElement("p");
    absatz.split("\n").forEach((t, i)=>{
      if(i) p.append(document.createElement("br"));
      zeile(p, t);
    });
    ziel.append(p);
  });
}

// Bild im Browser verkleinern, damit die Datenbank klein bleibt (JPEG-Data-URL).
function verkleinern(datei, kante=1000, guete=0.72){
  return new Promise((ok, fehler)=>{
    const leser = new FileReader();
    leser.onerror = () => fehler(new Error("Lesefehler"));
    leser.onload = () => {
      const bild = new Image();
      bild.onerror = () => fehler(new Error("Kein Bild"));
      bild.onload = () => {
        const f = Math.min(1, kante / Math.max(bild.width, bild.height));
        const c = document.createElement("canvas");
        c.width = Math.round(bild.width * f);
        c.height = Math.round(bild.height * f);
        c.getContext("2d").drawImage(bild, 0, 0, c.width, c.height);
        ok(c.toDataURL("image/jpeg", guete));
      };
      bild.src = leser.result;
    };
    leser.readAsDataURL(datei);
  });
}

/* ============================================================
   Aussehen aus SETTINGS (config.js)
   ============================================================ */
// Ältere config.js ohne SETTINGS sollen weiter funktionieren.
const EINSTELLUNG = (typeof SETTINGS === "object" && SETTINGS) || {};
const kitaName = String(EINSTELLUNG.name || "").trim();

// Nur Adressen auf der eigenen Domain zulassen (Grundregel: keine Fremdquellen).
const eigeneAdresse = pfad => {
  if(!pfad) return "";
  try{
    const u = new URL(pfad, location.href);
    return u.origin === location.origin ? u.href : "";
  }catch(e){ return ""; }
};
const farbe = f => /^#([0-9a-f]{3}|[0-9a-f]{6})$/i.test(String(f||"").trim()) ? String(f).trim() : "";

// Seitentitel mit Kitanamen, auch für Titel, die erst nach dem Laden feststehen.
const titel = t => {
  const zusatz = kitaName ? " · " + kitaName : "";
  document.title = String(t).endsWith(zusatz) ? t : t + zusatz;
};

(function(){
  // Farben sofort setzen, damit nichts in den Standardfarben aufblitzt
  const c = EINSTELLUNG.colors || {};
  const haupt = farbe(c.main), akzent = farbe(c.accent);
  const root = document.documentElement.style;
  if(haupt){
    root.setProperty("--moss", haupt);
    root.setProperty("--moss-soft", "color-mix(in srgb, " + haupt + " 15%, #fff)");
    const meta = document.querySelector('meta[name="theme-color"]');
    if(meta) meta.setAttribute("content", haupt);
  }
  if(akzent){
    root.setProperty("--berry", akzent);
    root.setProperty("--berry-soft", "color-mix(in srgb, " + akzent + " 13%, #fff)");
  }

  const favicon = eigeneAdresse(EINSTELLUNG.favicon);
  if(favicon){
    let link = document.querySelector('link[rel="icon"]');
    if(!link){ link = document.createElement("link"); link.rel = "icon"; document.head.appendChild(link); }
    link.href = favicon;
  }
  if(kitaName){
    const app = document.querySelector('meta[name="apple-mobile-web-app-title"][content="Kita"]');
    if(app) app.setAttribute("content", kitaName);
  }

  document.addEventListener("DOMContentLoaded", () => {
    titel(document.title);
    const logo = eigeneAdresse(EINSTELLUNG.logo);
    if(!kitaName && !logo) return;
    const ziel = document.querySelector(".wrap > header, .wrap > .bar-top");
    if(!ziel) return;
    const marke = document.createElement("div");
    marke.className = "marke";
    if(logo){
      const img = document.createElement("img");
      img.src = logo; img.alt = kitaName ? "Logo " + kitaName : "Logo";
      img.onerror = () => img.remove();
      marke.appendChild(img);
    }
    if(kitaName){
      const span = document.createElement("span");
      span.textContent = kitaName;
      marke.appendChild(span);
    }
    ziel.parentNode.insertBefore(marke, ziel);
  });
})();
