import { computeScore, type DimensionResult } from "@/lib/scoring";
import type { ScorePayload } from "@/lib/data";

const gradeColor: Record<string, string> = {
  A: "var(--a)", B: "var(--b)", C: "var(--c)", D: "var(--d)", E: "var(--e)",
};
const pct = (x: number) => `${Math.round(x * 100)}%`;

// Raison du plafond d'un pilier (gate), par dimension.
const capReason: Record<string, string> = {
  ANI: "exploitation animale",
  PLA: "pollueur plastique majeur",
};

export function CompanyScore({ payload }: { payload: ScorePayload }) {
  // Pondération fixe : profil renvoyé par la base (défaut « Équilibré »).
  const result = computeScore(payload);
  const chain = payload.ownership_chain ?? [];
  // code indicateur -> nom lisible (fourni par compute_score_input)
  const indicatorNames = new Map(
    payload.applicableIndicators.map((i) => [i.code, i.name ?? i.code]),
  );

  return (
    <main>
      <a className="muted small" href="/">← toutes les entreprises</a>

      {/* En-tête : note ET fiabilité, séparées */}
      <div className="panel" style={{ marginTop: 12 }}>
        <div className="row between wrap">
          <div>
            <h1 style={{ marginBottom: 2 }}>{payload.entity.name}</h1>
            <div className="muted small">
              {chain.length > 1 ? chain.join("  →  ") : "Groupe"}
            </div>
          </div>
          <div className="row" style={{ gap: 20 }}>
            <div style={{ textAlign: "center" }}>
              <div className={`grade grade-${result.grade}`}>{result.grade}</div>
              <div className="muted small" style={{ marginTop: 4 }}>Note · {pct(result.score)}</div>
            </div>
            <div style={{ minWidth: 160 }}>
              <div className="small">Fiabilité</div>
              <div className="meter" style={{ margin: "4px 0" }}>
                <span style={{ width: pct(result.confidence) }} />
              </div>
              <div className="muted small">
                {pct(result.confidence)} {result.publishable ? "" : "· données insuffisantes"}
              </div>
            </div>
          </div>
        </div>

        {/* Méta-scores */}
        {result.groups.length > 0 && (
          <div className="row wrap" style={{ marginTop: 14, gap: 10 }}>
            {result.groups.map((g) => (
              <span key={g.code} className="badge" style={{ borderColor: gradeColor[g.grade], color: gradeColor[g.grade] }}>
                {g.name} : {g.grade} ({pct(g.score)})
              </span>
            ))}
          </div>
        )}
      </div>

      {/* Détail par pilier */}
      {result.dimensions.map((d) => (
        <DimensionPanel key={d.dimension_code} d={d} names={indicatorNames} />
      ))}

      <p className="muted small" style={{ marginTop: 20 }}>
        Pondération : <strong>{payload.profile.name}</strong>. Méthodologie publique et versionnée.
      </p>
    </main>
  );
}

function DimensionPanel({ d, names }: { d: DimensionResult; names: Map<string, string> }) {
  const covered = d.indicators.filter((i) => i.covered);
  return (
    <div className="panel">
      <div className="row between">
        <div className="row" style={{ gap: 10 }}>
          <div className={`grade sm grade-${d.grade}`}>{d.grade}</div>
          <strong>{d.name}</strong>
        </div>
        <span className="muted small">
          fiabilité {pct(d.confidence)} · {d.covered_indicators}/{d.applicable_indicators} indicateurs
        </span>
      </div>

      <div className="row" style={{ margin: "10px 0 2px" }}>
        <div className="bar">
          <span style={{ width: pct(d.score), background: gradeColor[d.grade] }} />
        </div>
        <span className="small" style={{ width: 40, textAlign: "right" }}>{pct(d.score)}</span>
      </div>

      {d.capped_by_gate && (
        <span className="badge cap">⛔ Plafonné à {pct(d.ceiling ?? 0)} — {capReason[d.dimension_code] ?? "cause structurelle"}</span>
      )}

      {covered.length === 0 ? (
        <p className="muted small" style={{ marginTop: 10 }}>
          Aucune donnée publiée sur ce pilier — noté 0 (l'opacité n'est pas récompensée).
        </p>
      ) : (
        <div style={{ marginTop: 8 }}>
          {covered.map((i) => (
            <div className="evidence" key={i.indicator_code}>
              <div className="row between wrap" style={{ gap: 6 }}>
                <span className="small" title={i.indicator_code}>
                  {names.get(i.indicator_code) ?? i.indicator_code}
                </span>
                <span className="row" style={{ gap: 6 }}>
                  {i.capped_by_greenwashing && <span className="badge warn">engagement plafonné</span>}
                  {i.floored_by_low_tier && <span className="badge warn">source faible</span>}
                  <span className="badge">{i.nature}</span>
                  <strong className="small">{pct(i.value ?? 0)}</strong>
                </span>
              </div>
              <div className="muted small" style={{ marginTop: 3 }}>
                {i.source_url ? (
                  <a href={i.source_url} target="_blank" rel="noreferrer" style={{ textDecoration: "underline" }}>
                    <span className={`tier-${i.tier}`}>{i.source_code}</span> ↗
                  </a>
                ) : (
                  <span className={`tier-${i.tier}`}>{i.source_code}</span>
                )}
                {" · "}{i.observed_on}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
