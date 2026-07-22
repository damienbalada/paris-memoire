import { getAllScores, type EntityScore } from "@/lib/data";

export const dynamic = "force-dynamic";

const gradeColor: Record<string, string> = {
  A: "var(--a)", B: "var(--b)", C: "var(--c)", D: "var(--d)", E: "var(--e)",
};
const pct = (x: number) => `${Math.round(x * 100)}%`;
const frYearMonth = (iso: string | null) => {
  if (!iso) return "—";
  const [y, m] = iso.split("-");
  return `${m}/${y}`;
};

function Table({ rows, ranked = true }: { rows: EntityScore[]; ranked?: boolean }) {
  return (
    <div style={{ overflowX: "auto" }}>
      <table style={{ width: "100%", borderCollapse: "collapse", fontSize: 14 }}>
        <thead>
          <tr className="muted small">
            {ranked && <th style={{ textAlign: "left", padding: "6px 4px" }}>#</th>}
            <th style={{ textAlign: "left", padding: "6px 4px" }}>Entité</th>
            <th style={{ textAlign: "center", padding: "6px 4px" }}>Note</th>
            <th className="col-hide-mobile" style={{ textAlign: "right", padding: "6px 4px" }}>Score</th>
            <th style={{ textAlign: "right", padding: "6px 4px" }}>Fiabilité</th>
            <th className="col-hide-mobile" style={{ textAlign: "right", padding: "6px 4px" }}>Mis à jour</th>
          </tr>
        </thead>
        <tbody>
          {rows.map((r, i) => (
            <tr key={r.slug} style={{ borderTop: "1px solid var(--border)" }}>
              {ranked && <td className="muted small" style={{ padding: "8px 4px" }}>{i + 1}</td>}
              <td style={{ padding: "8px 4px" }}>
                <a href={`/entreprise/${r.slug}`} style={{ fontWeight: 600 }}>{r.name}</a>
                {r.group && <span className="muted small"> · {r.group}</span>}
              </td>
              <td style={{ textAlign: "center", padding: "8px 4px" }}>
                {ranked ? (
                  <span className={`grade sm grade-${r.grade}`} style={{ display: "inline-grid" }}>{r.grade}</span>
                ) : (
                  <span className="muted small">—</span>
                )}
              </td>
              <td style={{ textAlign: "right", padding: "8px 4px" }} className={`col-hide-mobile ${ranked ? "" : "muted"}`}>{pct(r.score)}</td>
              <td className="muted" style={{ textAlign: "right", padding: "8px 4px" }}>{pct(r.confidence)}</td>
              <td className="muted small col-hide-mobile" style={{ textAlign: "right", padding: "8px 4px" }}>{frYearMonth(r.last_observed)}</td>
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
  const byConfidence = (a: EntityScore, b: EntityScore) => b.confidence - a.confidence;
  // On ne classe QUE les entités dont la fiabilité dépasse le seuil de publication :
  // une note basse par manque de données n'est pas un mauvais score, c'est une absence.
  const ranked = scores.filter((s) => s.publishable);
  const unranked = scores.filter((s) => !s.publishable).sort(byConfidence);
  const groups = ranked.filter((s) => !s.is_brand).sort(byScore);
  const brands = ranked.filter((s) => s.is_brand).sort(byScore);

  return (
    <main>
      <h1>Classement</h1>
      <p className="muted small">
        Trié par note (profil « Équilibré »). Seules les entités dont la
        <strong> fiabilité dépasse 30 %</strong> sont classées : une note basse
        faute de données n'est pas un mauvais score, c'est une absence de preuves.
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

      {unranked.length > 0 && (
        <div className="panel" style={{ borderStyle: "dashed" }}>
          <h3>Non classées — données insuffisantes</h3>
          <p className="muted small" style={{ marginBottom: 10 }}>
            Fiabilité sous le seuil de 30 % : pas assez de preuves publiées pour
            attribuer une note défendable. Ce n'est pas un jugement négatif — c'est
            un manque de transparence de l'entité, ou une couverture encore partielle.
          </p>
          <Table rows={unranked} ranked={false} />
        </div>
      )}
    </main>
  );
}
