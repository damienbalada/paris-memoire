import { getAllScores, type EntityScore } from "@/lib/data";

export const dynamic = "force-dynamic";

const gradeColor: Record<string, string> = {
  A: "var(--a)", B: "var(--b)", C: "var(--c)", D: "var(--d)", E: "var(--e)",
};
const pct = (x: number) => `${Math.round(x * 100)}%`;

function Table({ rows }: { rows: EntityScore[] }) {
  return (
    <div style={{ overflowX: "auto" }}>
      <table style={{ width: "100%", borderCollapse: "collapse", fontSize: 14 }}>
        <thead>
          <tr className="muted small">
            <th style={{ textAlign: "left", padding: "6px 4px" }}>#</th>
            <th style={{ textAlign: "left", padding: "6px 4px" }}>Entité</th>
            <th style={{ textAlign: "center", padding: "6px 4px" }}>Note</th>
            <th style={{ textAlign: "right", padding: "6px 4px" }}>Score</th>
            <th style={{ textAlign: "right", padding: "6px 4px" }}>Fiabilité</th>
          </tr>
        </thead>
        <tbody>
          {rows.map((r, i) => (
            <tr key={r.slug} style={{ borderTop: "1px solid var(--border)" }}>
              <td className="muted small" style={{ padding: "8px 4px" }}>{i + 1}</td>
              <td style={{ padding: "8px 4px" }}>
                <a href={`/entreprise/${r.slug}`} style={{ fontWeight: 600 }}>{r.name}</a>
                {r.group && <span className="muted small"> · {r.group}</span>}
              </td>
              <td style={{ textAlign: "center", padding: "8px 4px" }}>
                <span className={`grade sm grade-${r.grade}`} style={{ display: "inline-grid" }}>{r.grade}</span>
              </td>
              <td style={{ textAlign: "right", padding: "8px 4px" }}>{pct(r.score)}</td>
              <td className="muted" style={{ textAlign: "right", padding: "8px 4px" }}>{pct(r.confidence)}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

export default async function ClassementPage() {
  let scores: EntityScore[] = [];
  let error: string | null = null;
  try {
    scores = await getAllScores();
  } catch (e) {
    error = (e as Error).message;
  }
  const byScore = (a: EntityScore, b: EntityScore) => b.score - a.score || b.confidence - a.confidence;
  const groups = scores.filter((s) => !s.is_brand).sort(byScore);
  const brands = scores.filter((s) => s.is_brand).sort(byScore);

  return (
    <main>
      <h1>Classement</h1>
      <p className="muted small">
        Trié par note (profil « Équilibré »). La fiabilité indique la part de
        données disponibles — une note haute avec fiabilité basse reste à confirmer.
      </p>

      {error && (
        <div className="panel" style={{ borderColor: "#6b2222" }}>
          <strong>Chargement impossible.</strong>
          <p className="muted small">{error}</p>
        </div>
      )}

      {groups.length > 0 && (
        <div className="panel">
          <h3>Groupes</h3>
          <Table rows={groups} />
        </div>
      )}
      {brands.length > 0 && (
        <div className="panel">
          <h3>Marques</h3>
          <Table rows={brands} />
        </div>
      )}
    </main>
  );
}
