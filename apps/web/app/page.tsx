import { getAllScores, listEntities } from "@/lib/data";

export const dynamic = "force-dynamic";

export default async function HomePage() {
  let entities: Awaited<ReturnType<typeof listEntities>> = [];
  let grades = new Map<string, string>();
  let error: string | null = null;
  try {
    const [ents, scores] = await Promise.all([listEntities(), getAllScores()]);
    entities = ents;
    grades = new Map(scores.map((s) => [s.slug, s.grade]));
  } catch (e) {
    error = (e as Error).message;
  }

  const name = (e: any) => e.display_name ?? e.legal_name;
  const byName = (a: any, b: any) =>
    String(name(a)).localeCompare(String(name(b)), "fr", { sensitivity: "base" });
  const groups = entities.filter((e) => !e.is_brand).sort(byName);
  const brands = entities.filter((e) => e.is_brand).sort(byName);

  // Une entité = une ligne. La note lettrée à gauche donne le repère visuel ;
  // « — » signale une entité pas encore notée (aucune preuve publiée).
  const Row = (e: any) => {
    const g = grades.get(e.slug);
    return (
      <a key={e.slug} className="ent-row" href={`/entreprise/${e.slug}`}>
        {g ? (
          <span className={`grade sm grade-${g}`}>{g}</span>
        ) : (
          <span className="grade sm grade-none" title="Pas encore notée">—</span>
        )}
        <span className="ent-name">{name(e)}</span>
        <span className="chev" aria-hidden="true">›</span>
      </a>
    );
  };

  return (
    <main className="fiche-stack">
      <div>
        <h1 style={{ marginBottom: 8 }}>DIAMS — score éthique des marques</h1>
        <p className="muted" style={{ margin: 0 }}>
          <strong>D</strong>ocumented, <strong>I</strong>ndependent, <strong>A</strong>uditable,{" "}
          <strong>M</strong>ulti-criteria <strong>S</strong>coring. Une note par dimension, un
          indice de fiabilité affiché à part, et chaque point traçable jusqu'à sa source datée.
        </p>
        <div className="row wrap" style={{ gap: 10, marginTop: 16 }}>
          <a className="btn" href="/classement">Voir le classement →</a>
          <a className="btn" href="/civique">DIAMS Civique (votes des partis) →</a>
        </div>
      </div>

      {error && (
        <div className="panel" style={{ borderColor: "#6b2222" }}>
          <strong>Connexion Supabase non configurée.</strong>
          <p className="muted small">Renseignez <code>.env</code> (voir <code>.env.example</code>). {error}</p>
        </div>
      )}

      {groups.length > 0 && (
        <section>
          <h2 className="list-title">Groupes <span className="muted">{groups.length}</span></h2>
          <div className="ent-list">{groups.map(Row)}</div>
        </section>
      )}

      {brands.length > 0 && (
        <section>
          <h2 className="list-title">Marques <span className="muted">{brands.length}</span></h2>
          <div className="ent-list">{brands.map(Row)}</div>
        </section>
      )}
    </main>
  );
}
