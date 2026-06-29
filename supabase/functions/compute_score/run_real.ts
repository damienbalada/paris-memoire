// Harness de validation : exécute le moteur (scoring.ts) sur des entrées
// RÉELLES assemblées depuis la base via la fonction SQL compute_score_input().
//   node --experimental-strip-types run_real.ts payload.json
import { readFileSync } from "node:fs";
import { computeScore, type ScoreInput } from "./scoring.ts";

const data = JSON.parse(readFileSync(process.argv[2] ?? "payload.json", "utf8")) as Record<string, any>;

for (const [key, p] of Object.entries(data)) {
  const input: ScoreInput = {
    applicableIndicators: p.applicableIndicators,
    evidence: p.evidence,
    dimensions: p.dimensions,
    profileWeights: p.profileWeights,
    dimensionGroups: p.dimensionGroups,
    tierConfig: p.tierConfig,
    natureConfig: p.natureConfig,
    params: p.params,
    peerValues: p.peerValues,
  };
  const r = computeScore(input);
  console.log("============================================================");
  console.log(`# ${key}`);
  console.log(`Entité : ${p.entity.name}  | chaîne : ${(p.ownership_chain ?? []).join(" → ")}`);
  console.log(`Profil : ${p.profile.name}`);
  console.log(`NOTE GLOBALE : ${r.grade} (${r.score.toFixed(3)})  |  FIABILITÉ : ${(r.confidence * 100).toFixed(0)}%  |  publiable : ${r.publishable}`);
  for (const g of r.groups) console.log(`  méta « ${g.name} » : ${g.grade} (${g.score.toFixed(3)})  fiab ${(g.confidence * 100).toFixed(0)}%`);
  console.log("Dimensions :");
  for (const d of r.dimensions) {
    const cap = d.capped_by_gate ? `  ⛔PLAFOND=${d.ceiling!.toFixed(2)}` : "";
    console.log(`  ${d.dimension_code}  ${d.grade}  score=${d.score.toFixed(3)}  conf=${d.confidence.toFixed(2)}  (${d.covered_indicators}/${d.applicable_indicators} couverts)${cap}`);
    for (const ind of d.indicators.filter((x) => x.covered)) {
      const flags = [ind.capped_by_greenwashing ? "PLAFOND-greenwashing" : "", ind.floored_by_low_tier ? "PLANCHER-tier-bas" : ""].filter(Boolean).join(",");
      console.log(`       - ${ind.indicator_code}: ${ind.value!.toFixed(3)} [${ind.nature}/${ind.tier}] ${flags}`);
    }
  }
}
