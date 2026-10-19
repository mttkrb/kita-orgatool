// Nachbau der Supabase-Schnittstelle (PostgREST) für die Seitentests, nur so weit,
// wie die Elternseiten ihn brauchen. Bildet die Rechte der echten Datenbank nach,
// auch ihre Fehler: Wer nach token filtert oder token liest, bekommt 42501, weil anon
// die Spalte nicht lesen darf. Nicht freundlicher machen als die Wirklichkeit.
// Die echten Policies prüft tests/sql/rechte.sql gegen Postgres; wer dort etwas
// ändert, gleicht es hier an.
const URL_PROJEKT = "https://projekt.supabase.test";
const ANON = "anon-test-key";
const ORGA = "orga-test-passwort";

// Wie intern.kurzname() in migration-26.sql
const kurzname = n => {
  const t = String(n).trim().split(/\s+/);
  return t.length < 2 ? t[0] : t[0] + " " + t[t.length - 1][0] + ".";
};

function fakeDb(start = {}){
  const db = {
    events: [], signups: [], payments: [], task_claims: [], task_images: [],
    ...JSON.parse(JSON.stringify(start)),
    anfragen: []
  };
  const antwort = (status, body) =>
    new Response(body === undefined ? null : JSON.stringify(body), { status });
  const verboten = () => antwort(403, { code:"42501", message:"permission denied for table signups" });
  const eq = (q, spalte) => {
    const v = q.get(spalte);
    return v && v.startsWith("eq.") ? v.slice(3) : null;
  };

  async function fetch(url, opt = {}){
    const methode = (opt.method || "GET").toUpperCase();
    const kopf = Object.fromEntries(Object.entries(opt.headers || {}).map(([k,v])=>[k.toLowerCase(), v]));
    const body = opt.body ? JSON.parse(opt.body) : null;
    db.anfragen.push({ methode, url, kopf, body });
    const u = new URL(url);
    if(u.origin !== URL_PROJEKT || kopf.apikey !== ANON) return antwort(401, { message:"Invalid API key" });
    const [, tabelle] = u.pathname.match(/^\/rest\/v1\/(.+)$/) || [];
    const q = u.searchParams;
    const orga = kopf["x-orga-key"] === ORGA;
    const token = kopf["x-entry-token"];

    if(tabelle === "events" && methode === "GET"){
      const slug = eq(q, "slug");
      return antwort(200, db.events.filter(e => !slug || e.slug === slug));
    }

    if(tabelle === "rpc/anmeldungen_oeffentlich" && methode === "POST"){
      const events = (body.p_events || []).slice(0, 50);
      return antwort(200, db.signups.filter(s => events.includes(s.event)).map(s => {
        const ev = db.events.find(e => e.slug === s.event) || {};
        const v = ev.visibility || {};
        const ab = s.status === "absage";
        return { event:s.event, adults:ab ? 0 : s.adults, kids:ab ? 0 : s.kids,
          items:ab ? [] : s.items, tasks:ab ? [] : s.tasks, status:s.status,
          name:!ab && (v.itemNames !== false || v.taskNames !== false) ? kurzname(s.name) : null };
      }));
    }

    if(tabelle === "signups"){
      // Spaltenrecht: token ist für anon gesperrt, auch fürs Orgateam (dieselbe Rolle)
      if(q.has("token") || (q.get("select") || "").split(",").includes("token")) return verboten();
      if(methode !== "POST" && (q.get("select") || "") === "*") return verboten();
      // Policy "anmelden" (migration-26): Orgateam oder eigenes Token
      const sichtbar = s => orga || (token && s.token === token);
      const id = eq(q, "id");
      const treffer = () => db.signups.filter(s => sichtbar(s) && (!id || s.id === id));
      const ohneToken = s => { const { token, ...rest } = s; return rest; };

      if(methode === "GET") return antwort(200, treffer().map(ohneToken));
      if(methode === "POST"){
        if(!body.id || !body.event || !body.token || !body.name) return antwort(400, { code:"23502" });
        if(String(body.name).length > 200) return antwort(400, { code:"23514" });
        db.signups.push({ adults:0, kids:0, items:[], tasks:[], fields:{}, note:null, status:null,
          created_at:new Date().toISOString(), ...body });
        return antwort(201);
      }
      if(methode === "PATCH"){
        if("token" in body || "id" in body) return verboten();
        treffer().forEach(s => Object.assign(s, body));
        return antwort(204);
      }
      if(methode === "DELETE"){
        // migration-24: Eltern löschen keine Anmeldung, für die schon bezahlt ist
        const weg = treffer().filter(s => orga || !db.payments.some(p => p.signup_id === s.id));
        db.signups = db.signups.filter(s => !weg.includes(s));
        db.payments = db.payments.filter(p => !weg.some(s => s.id === p.signup_id));
        return (kopf.prefer || "").includes("return=representation")
          ? antwort(200, weg.map(s => ({ id:s.id }))) : antwort(204);
      }
    }

    if(tabelle === "task_claims" && methode === "GET"){
      const ev = eq(q, "event_id");
      return antwort(200, db.task_claims.filter(c => c.event_id === ev));
    }
    if(tabelle === "task_images" && methode === "GET"){
      const ev = eq(q, "event_id");
      return antwort(200, db.task_images.filter(c => c.event_id === ev));
    }

    // Was hier nicht nachgebaut ist, soll im Test auffallen
    db.unbekannt = (db.unbekannt || []).concat(methode + " " + url);
    return antwort(404, { message:"Im Nachbau nicht vorhanden: " + methode + " " + u.pathname });
  }

  db.fetch = fetch;
  return db;
}

module.exports = { fakeDb, SUPABASE: { url:URL_PROJEKT, anonKey:ANON }, ORGA };
