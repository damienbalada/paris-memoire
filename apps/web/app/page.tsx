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

  const groups = entities.filter((e) => !e.is_brand);
  const brands = entities.filter((e) => e.is_brand);
  const name = (e: any) => e.display_name ?? e.legal_name;

  const Chip = (e: any) => (
    <a key={e.slug} className="chip-link row" style={{ gap: 8, alignItems: "center" }} href={`/entreprise/${e.slug}`}>
      {grades.get(e.slug) && (
        <span className={`grade sm grade-${grades.get(e.slug)}`}
              style={{ width: 22, height: 22, fontSize: 12, borderRadius: 6 }}>
          {grades.get(e.slug)}
        </span>
      )}
      <span>{name(e)}</span>
    </a>
  );

  return (
    <main>
      <h1>Score éthique des marques</h1>
      <p className="muted">
        Une note par dimension, un indice de fiabilité affiché à part, et chaque
        point traçable jusqu'à sa source datée. <a href="/classement" style={{ textDecoration: "underline" }}>Voir le classement →</a>
      </p>

      {error && (
        <div className="panel" style={{ borderColor: "#6b2222" }}>
          <strong>Connexion Supabase non configurée.</strong>
          <p className="muted small">Renseignez <code>.env</code> (voir <code>.env.example</code>). {error}</p>
        </div>
      )}

      {groups.length > 0 && (
        <div className="panel">
          <h3>Groupes</h3>
          <div className="row wrap">{groups.map(Chip)}</div>
        </div>
      )}

      {brands.length > 0 && (
        <div className="panel">
          <h3>Marques</h3>
          <div className="row wrap">{brands.map(Chip)}</div>
        </div>
      )}
    </main>
  );
}
