// Tests unitaires du moteur de scoring (logique pure).
// Lancer : node --test --experimental-strip-types supabase/functions/compute_score/scoring.test.ts
import { test } from "node:test";
import assert from "node:assert/strict";
import {
  computeScore,
  toGrade,
  type Evidence,
  type Indicator,
  type ScoreInput,
  type Tier,
  type Nature,
} from "./scoring.ts";

// --- config de référence (miroir des tables de config en base) ---------------
const tierConfig: ScoreInput["tierConfig"] = {
  regulatory:  { evidence_weight: 1.0,  max_confidence: 1.0,  can_penalize_alone: true,  min_score_floor_alone: 0.0 },
  audited_ngo: { evidence_weight: 0.8,  max_confidence: 0.85, can_penalize_alone: true,  min_score_floor_alone: 0.0 },
  press:       { evidence_weight: 0.35, max_confidence: 0.45, can_penalize_alone: false, min_score_floor_alone: 0.3 },
  crowd:       { evidence_weight: 0.2,  max_confidence: 0.3,  can_penalize_alone: false, min_score_floor_alone: 0.4 },
};
const natureConfig: ScoreInput["natureConfig"] = {
  result:      { score_multiplier: 1.0, max_score_without_result: null },
  policy:      { score_multiplier: 0.7, max_score_without_result: 0.6 },
  commitment:  { score_multiplier: 0.4, max_score_without_result: 0.5 },
  controversy: { score_multiplier: 1.0, max_score_without_result: null },
};
const params = { missing_data_score: 0, missing_data_confidence: 0, min_confidence_to_publish: 0.3 };

// --- helpers -----------------------------------------------------------------
function ev(partial: Partial<Evidence> & { indicator_code: string }): Evidence {
  return {
    tier: "regulatory",
    nature: "result",
    normalized_value: null,
    value_numeric: null,
    confidence: 0.9,
    observed_on: "2024-01-01",
    specificity: 2,
    ...partial,
  };
}
function ind(code: string, dim: string, extra: Partial<Indicator> = {}): Indicator {
  return { code, dimension_code: dim, kind: "binary", direction: "higher_better", weight: 1, ...extra };
}
function baseInput(over: Partial<ScoreInput>): ScoreInput {
  return {
    applicableIndicators: [],
    evidence: [],
    dimensions: [{ code: "ENV", name: "Environnement" }, { code: "ANI", name: "Animal" }],
    profileWeights: [{ dimension_code: "ENV", weight: 1 }, { dimension_code: "ANI", weight: 1 }],
    dimensionGroups: [],
    tierConfig,
    natureConfig,
    params,
    ...over,
  };
}

// --- Règle 1 : donnée manquante = 0 ------------------------------------------
test("règle 1 — dimension sans evidence : score 0 et confiance 0", () => {
  const res = computeScore(baseInput({
    applicableIndicators: [ind("ENV_A", "ENV"), ind("ENV_B", "ENV")],
    evidence: [],
    profileWeights: [{ dimension_code: "ENV", weight: 1 }],
  }));
  const env = res.dimensions.find((d) => d.dimension_code === "ENV")!;
  assert.equal(env.score, 0);
  assert.equal(env.confidence, 0);
  assert.equal(env.covered_indicators, 0);
  assert.equal(res.publishable, false); // confiance 0 < seuil
});

test("règle 1 — donnée partielle : l'indicateur manquant tire le score vers le bas", () => {
  const res = computeScore(baseInput({
    applicableIndicators: [ind("ENV_A", "ENV"), ind("ENV_B", "ENV")],
    evidence: [ev({ indicator_code: "ENV_A", normalized_value: 1.0 })], // ENV_B manquant
    profileWeights: [{ dimension_code: "ENV", weight: 1 }],
  }));
  const env = res.dimensions.find((d) => d.dimension_code === "ENV")!;
  // (1.0*1 + 0*1) / 2 = 0.5
  assert.equal(env.score, 0.5);
  assert.equal(env.covered_indicators, 1);
});

// --- Règle 3 : anti-greenwashing --------------------------------------------
test("règle 3 — une politique seule est plafonnée à 0.6", () => {
  const res = computeScore(baseInput({
    applicableIndicators: [ind("ENV_A", "ENV")],
    evidence: [ev({ indicator_code: "ENV_A", nature: "policy", normalized_value: 1.0 })],
    profileWeights: [{ dimension_code: "ENV", weight: 1 }],
  }));
  const r = res.dimensions[0].indicators[0];
  assert.equal(r.value, 0.6);
  assert.equal(r.capped_by_greenwashing, true);
});

test("règle 3 — un engagement seul est faible (×0.4)", () => {
  const res = computeScore(baseInput({
    applicableIndicators: [ind("ENV_A", "ENV")],
    evidence: [ev({ indicator_code: "ENV_A", nature: "commitment", normalized_value: 1.0 })],
    profileWeights: [{ dimension_code: "ENV", weight: 1 }],
  }));
  assert.equal(res.dimensions[0].indicators[0].value, 0.4);
});

test("règle 3 — un résultat débloque le plein potentiel", () => {
  const res = computeScore(baseInput({
    applicableIndicators: [ind("ENV_A", "ENV")],
    evidence: [
      ev({ indicator_code: "ENV_A", nature: "policy", normalized_value: 1.0 }),
      ev({ indicator_code: "ENV_A", nature: "result", normalized_value: 0.9 }),
    ],
    profileWeights: [{ dimension_code: "ENV", weight: 1 }],
  }));
  const r = res.dimensions[0].indicators[0];
  assert.equal(r.value, 0.9);
  assert.equal(r.nature, "result");
  assert.ok(!r.capped_by_greenwashing);
});

// --- Règle 2 : tiers (poids + plafond confiance + plancher anti-presse) -------
test("règle 2 — la confiance d'une source presse est plafonnée à 0.45", () => {
  const res = computeScore(baseInput({
    applicableIndicators: [ind("ANI_A", "ANI")],
    evidence: [ev({ indicator_code: "ANI_A", tier: "press", confidence: 0.95, normalized_value: 0.8 })],
    profileWeights: [{ dimension_code: "ANI", weight: 1 }],
  }));
  assert.equal(res.dimensions[0].indicators[0].confidence, 0.45);
});

test("règle 2 — une controverse presse seule ne peut pas descendre sous le plancher 0.3", () => {
  const res = computeScore(baseInput({
    applicableIndicators: [ind("ANI_A", "ANI")],
    // pas de positive -> base 0.5 ; controverse presse sévérité max
    evidence: [ev({ indicator_code: "ANI_A", tier: "press", nature: "controversy", normalized_value: 1.0 })],
    profileWeights: [{ dimension_code: "ANI", weight: 1 }],
  }));
  const r = res.dimensions[0].indicators[0];
  // 0.5 * (1 - 1.0*0.35) = 0.325, plancher 0.3 respecté
  assert.ok(r.value! >= 0.3, `value=${r.value}`);
  assert.ok(Math.abs(r.value! - 0.325) < 1e-9);
});

test("règle 2 — une controverse régulatoire peut pénaliser fortement (pas de plancher)", () => {
  const res = computeScore(baseInput({
    applicableIndicators: [ind("ANI_A", "ANI")],
    evidence: [
      ev({ indicator_code: "ANI_A", nature: "result", normalized_value: 1.0 }),
      ev({ indicator_code: "ANI_A", tier: "regulatory", nature: "controversy", normalized_value: 1.0 }),
    ],
    profileWeights: [{ dimension_code: "ANI", weight: 1 }],
  }));
  // 1.0 * (1 - 1.0*1.0) = 0
  assert.equal(res.dimensions[0].indicators[0].value, 0);
});

// --- Héritage groupe -> marque ----------------------------------------------
test("héritage — une marque hérite de l'evidence du groupe", () => {
  const res = computeScore(baseInput({
    applicableIndicators: [ind("ENV_A", "ENV")],
    // evidence portée par le groupe (specificity 0), aucune evidence propre
    evidence: [ev({ indicator_code: "ENV_A", nature: "result", normalized_value: 0.7, specificity: 0 })],
    profileWeights: [{ dimension_code: "ENV", weight: 1 }],
  }));
  assert.equal(res.dimensions[0].indicators[0].covered, true);
  assert.equal(res.dimensions[0].indicators[0].value, 0.7);
});

test("héritage — l'evidence propre de la marque prime sur celle du groupe", () => {
  const res = computeScore(baseInput({
    applicableIndicators: [ind("ENV_A", "ENV")],
    evidence: [
      ev({ indicator_code: "ENV_A", nature: "result", normalized_value: 0.5, specificity: 0 }), // groupe
      ev({ indicator_code: "ENV_A", nature: "result", normalized_value: 0.9, specificity: 2 }), // marque
    ],
    profileWeights: [{ dimension_code: "ENV", weight: 1 }],
  }));
  assert.equal(res.dimensions[0].indicators[0].value, 0.9);
});

// --- Normalisation intra-secteur (percentile live) ---------------------------
test("normalisation — quantitatif lower_better via percentile intra-secteur", () => {
  const res = computeScore(baseInput({
    applicableIndicators: [ind("LAB_RATIO", "ENV", { kind: "quantitative", direction: "lower_better" })],
    evidence: [ev({ indicator_code: "LAB_RATIO", nature: "result", value_numeric: 50 })],
    peerValues: { LAB_RATIO: [10, 50, 100, 200] }, // 50 est bas -> bon pour lower_better
    profileWeights: [{ dimension_code: "ENV", weight: 1 }],
  }));
  // percentile(50) = (1 + 0.5)/4 = 0.375 ; lower_better -> 1-0.375 = 0.625
  assert.ok(Math.abs(res.dimensions[0].indicators[0].value! - 0.625) < 1e-9);
});

// --- Pondération par profil --------------------------------------------------
test("profil — un profil qui surpondère ENV change la note globale", () => {
  const common = {
    applicableIndicators: [ind("ENV_A", "ENV"), ind("ANI_A", "ANI")],
    evidence: [
      ev({ indicator_code: "ENV_A", nature: "result", normalized_value: 1.0 }), // ENV excellent
      ev({ indicator_code: "ANI_A", nature: "result", normalized_value: 0.0 }), // ANI nul
    ],
  };
  const equilibre = computeScore(baseInput({
    ...common,
    profileWeights: [{ dimension_code: "ENV", weight: 0.5 }, { dimension_code: "ANI", weight: 0.5 }],
  }));
  const ecolo = computeScore(baseInput({
    ...common,
    profileWeights: [{ dimension_code: "ENV", weight: 0.8 }, { dimension_code: "ANI", weight: 0.2 }],
  }));
  assert.equal(equilibre.score, 0.5);            // (1.0*0.5 + 0*0.5)
  assert.ok(Math.abs(ecolo.score - 0.8) < 1e-9); // (1.0*0.8 + 0*0.2)
  assert.ok(ecolo.score > equilibre.score);
});

// --- Méta-score (groupe de dimensions) ---------------------------------------
test("méta-score — agrège les dimensions membres", () => {
  const res = computeScore(baseInput({
    applicableIndicators: [ind("ANI_A", "ANI"), ind("ENV_A", "ENV")],
    evidence: [
      ev({ indicator_code: "ANI_A", nature: "result", normalized_value: 0.4 }),
      ev({ indicator_code: "ENV_A", nature: "result", normalized_value: 0.8 }),
    ],
    dimensionGroups: [{ code: "LIVING", name: "Bien-être du vivant", members: [{ dimension_code: "ANI", weight: 1 }] }],
    profileWeights: [{ dimension_code: "ENV", weight: 1 }, { dimension_code: "ANI", weight: 1 }],
  }));
  const living = res.groups.find((g) => g.code === "LIVING")!;
  assert.equal(living.score, 0.4);
  assert.equal(living.grade, "C");
});

// --- Notes lettrées ----------------------------------------------------------
test("toGrade — seuils", () => {
  assert.equal(toGrade(0.85), "A");
  assert.equal(toGrade(0.6), "B");
  assert.equal(toGrade(0.4), "C");
  assert.equal(toGrade(0.2), "D");
  assert.equal(toGrade(0.1), "E");
});
