// Gemeinsame Hilfsfunktionen aller Seiten.
// Wird nach config.js und vor dem Skript der Seite geladen.

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
