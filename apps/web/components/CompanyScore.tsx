import { computeScore, type DimensionResult, type ScoreResult } from "@/lib/scoring";
import type { ScorePayload } from "@/lib/data";

const gradeColor: Record<string, string> = {
  A: "var(--a)", B: "var(--b)", C: "var(--c)", D: "var(--d)", E: "var(--e)",
};
const pct = (x: number) => `${Math.round(x * 100)}%`;

// Date ISO -> "JJ/MM/AAAA" (affichage FR).
const frDate = (iso?: string | null) => {
  if (!iso) return null;
  const [y, m, d] = iso.split("-");
  return d ? `${d}/${m}/${y}` : `${m}/${y}`;
};
// Une preuve est "ancienne" au-delà de 3 ans (décote totale à 5 ans).
const STALE_BEFORE = new Date(Date.now() - 3 * 365 * 24 * 3600 * 1000)
  .toISOString()
  .slice(0, 10);

// Raison du plafond d'un pilier (gate), par dimension.
const capReason: Record<string, string> = {
  ANI: "exploitation animale",
  PLA: "pollueur plastique majeur",
};

export function CompanyScore({
  payload,
  group = null,
}: {
  payload: ScorePayload;
  group?: { name: string; result: ScoreResult } | null;
}) {
  // Pondération fixe : profil renvoyé par la base (défaut « Équilibré »).
  const result = computeScore(payload);
  const chain = payload.ownership_chain ?? [];

  // La marque a-t-elle des preuves PROPRES ? L'evidence de l'entité notée porte
  // la spécificité maximale (chain.length - 1) ; en dessous, c'est de l'héritage.
  const ownSpec = Math.max(0, chain.length - 1);
  const hasOwnEvidence = (payload.evidence ?? []).some((e) => e.specificity >= ownSpec);

  // Comparaison marque ↔ groupe propriétaire : on repère les piliers qui
  // divergent nettement (≥ 20 points). Les piliers où la marque fait bien mieux
  // que son groupe (≥ 30 points) déclenchent une alerte « circuit de l'argent ».
  const groupDims = new Map((group?.result.dimensions ?? []).map((d) => [d.dimension_code, d]));
  const divergences = group
    ? result.dimensions
        .map((d) => ({ d, g: groupDims.get(d.dimension_code) }))
        .filter((x) => x.g && Math.abs(x.d.score - x.g!.score) >= 0.2)
        .map((x) => ({
          code: x.d.dimension_code,
          name: x.d.name,
          markGrade: x.d.grade,
          groupGrade: x.g!.grade,
          diff: x.d.score - x.g!.score,
        }))
    : [];
  const betterThanGroup = divergences.filter((x) => x.diff >= 0.3);
  // code indicateur -> nom lisible (fourni par compute_score_input)
  const indicatorNames = new Map(
    payload.applicableIndicators.map((i) => [i.code, i.name ?? i.code]),
  );

  // Piliers NON PERTINENTS pour ce secteur (aucun indicateur applicable) :
  // à distinguer d'un pilier applicable mais sans donnée (lui, noté 0).
  const applicableDims = new Set(payload.applicableIndicators.map((i) => i.dimension_code));
  const notApplicable = (payload.dimensions ?? []).filter((d) => !applicableDims.has(d.code));

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
            {result.last_observed && (
              <div className="muted small" style={{ marginTop: 2 }}>
                Dernière mise à jour · {frDate(result.last_observed)}
              </div>
            )}
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

      {/* Encart marque ↔ groupe propriétaire */}
      {group && (
        <div className="panel" style={{ borderColor: "#3a4256" }}>
          <div className="row between wrap" style={{ gap: 8 }}>
            <div>
              <strong>🏭 Groupe propriétaire : {group.name}</strong>
              <div className="muted small">À qui va l'argent quand vous achetez cette marque.</div>
            </div>
            <span className="badge" style={{ borderColor: gradeColor[group.result.grade], color: gradeColor[group.result.grade] }}>
              Note du groupe : {group.result.grade} ({pct(group.result.score)})
            </span>
          </div>

          {!hasOwnEvidence && (
            <div className="muted small" style={{ marginTop: 10 }}>
              Aucune donnée propre à la marque : sa note <strong>reflète entièrement celle du groupe {group.name}</strong>.
              La transparence et les engagements sont pilotés au niveau du groupe.
            </div>
          )}

          {divergences.length > 0 && (
            <div style={{ marginTop: 12 }}>
              <div className="muted small" style={{ marginBottom: 4 }}>Écarts marque ↔ groupe :</div>
              {divergences.map((x) => (
                <div className="row between" key={x.code} style={{ padding: "5px 0", borderTop: "1px solid var(--border)" }}>
                  <span className="small">{x.name}</span>
                  <span className="row" style={{ gap: 6 }}>
                    <span className={`grade sm grade-${x.markGrade}`} style={{ width: 22, height: 22, fontSize: 11, borderRadius: 6 }}>{x.markGrade}</span>
                    <span className="muted small">marque</span>
                    <span className="muted">→</span>
                    <span className={`grade sm grade-${x.groupGrade}`} style={{ width: 22, height: 22, fontSize: 11, borderRadius: 6 }}>{x.groupGrade}</span>
                    <span className="muted small">groupe</span>
                  </span>
                </div>
              ))}
            </div>
          )}

          {betterThanGroup.length > 0 && (
            <span className="badge warn" style={{ marginTop: 12, display: "inline-block", whiteSpace: "normal", lineHeight: 1.4 }}>
              ⚠️ Cette marque est nettement mieux notée que son groupe sur : {betterThanGroup.map((x) => x.name).join(", ")}.
              Votre achat bénéficie tout de même au groupe {group.name}.
            </span>
          )}
        </div>
      )}

      {/* Détail par pilier */}
      {result.dimensions.map((d) => (
        <DimensionPanel key={d.dimension_code} d={d} names={indicatorNames} />
      ))}

      {/* Piliers non pertinents pour le secteur (exclus du calcul, pas pénalisés) */}
      {notApplicable.length > 0 && (
        <div className="panel" style={{ borderStyle: "dashed" }}>
          <div className="muted small">
            <strong>Non applicable à ce secteur</strong> — exclu du calcul (ni bonus, ni malus) :{" "}
            {notApplicable.map((d) => d.name).join(", ")}.
          </div>
        </div>
      )}

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
      <div className="row between wrap" style={{ gap: 6 }}>
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
                  {i.unscored_controversy && <span className="badge warn" title="Source unique non corroborée : signalée mais exclue du calcul de la note.">controverse · hors note</span>}
                  <span className="badge">{i.nature}</span>
                  {i.display_only ? (
                    <span className="muted small">—</span>
                  ) : (
                    <strong className="small">{pct(i.value ?? 0)}</strong>
                  )}
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
                {" · "}{frDate(i.observed_on) ?? i.observed_on}
                {i.observed_on && i.observed_on < STALE_BEFORE && (
                  <span className="badge warn" style={{ marginLeft: 6 }} title="Preuve de plus de 3 ans — à rafraîchir (décote totale à 5 ans).">donnée ancienne</span>
                )}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
