import { listEntities } from "@/lib/data";

export const dynamic = "force-dynamic";

export default async function HomePage() {
  let entities: Awaited<ReturnType<typeof listEntities>> = [];
  let error: string | null = null;
  try {
    entities = await listEntities();
  } catch (e) {
    error = (e as Error).message;
  }

  const groups = entities.filter((e) => !e.is_brand);
  const brands = entities.filter((e) => e.is_brand);
  const name = (e: any) => e.display_name ?? e.legal_name;

  return (
    <main>
      <h1>Score éthique des marques de luxe</h1>
      <p className="muted">
        Une note par dimension, un indice de fiabilité affiché à part, et chaque
        point traçable jusqu'à sa source datée.
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
          <div>{groups.map((e) => (
            <a key={e.slug} className="chip-link" href={`/entreprise/${e.slug}`}>{name(e)}</a>
          ))}</div>
        </div>
      )}

      {brands.length > 0 && (
        <div className="panel">
          <h3>Marques</h3>
          <div>{brands.map((e) => (
            <a key={e.slug} className="chip-link" href={`/entreprise/${e.slug}`}>{name(e)}</a>
          ))}</div>
        </div>
      )}
    </main>
  );
}
