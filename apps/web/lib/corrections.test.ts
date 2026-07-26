// Tests de la validation des signalements (logique pure).
// Lancer : node --test --experimental-strip-types apps/web/lib/corrections.test.ts
import { test } from "node:test";
import assert from "node:assert/strict";
import { validateCorrection, CORRECTION_KINDS } from "./corrections.ts";

const base = {
  entity_slug: "nestle",
  kind: "wrong",
  message: "La note de gouvernance ignore la sanction de mars 2026.",
};

test("accepte un signalement minimal valide", () => {
  const r = validateCorrection({ ...base });
  assert.equal(r.ok, true);
  if (!r.ok) return;
  assert.equal(r.value.entity_slug, "nestle");
  assert.equal(r.value.kind, "wrong");
  // Les champs facultatifs absents deviennent null, jamais "" (contrainte base).
  assert.equal(r.value.source_url, null);
  assert.equal(r.value.contact, null);
  assert.equal(r.value.indicator_code, null);
});

test("les chaînes vides deviennent null et ne cassent pas la validation", () => {
  const r = validateCorrection({ ...base, source_url: "", contact: "  ", indicator_code: "" });
  assert.equal(r.ok, true);
  if (!r.ok) return;
  assert.equal(r.value.source_url, null);
  assert.equal(r.value.contact, null);
  assert.equal(r.value.indicator_code, null);
});

test("refuse un type de signalement inconnu", () => {
  const r = validateCorrection({ ...base, kind: "boycott" });
  assert.equal(r.ok, false);
});

test("tous les types déclarés sont acceptés", () => {
  for (const kind of Object.keys(CORRECTION_KINDS)) {
    assert.equal(validateCorrection({ ...base, kind }).ok, true, kind);
  }
});

test("refuse un message trop court (bornes alignées sur la contrainte CHECK)", () => {
  assert.equal(validateCorrection({ ...base, message: "faux" }).ok, false);
  // Le trim compte : 10 espaces + 3 lettres = 3 caractères utiles.
  assert.equal(validateCorrection({ ...base, message: "          abc" }).ok, false);
});

test("refuse un message trop long", () => {
  assert.equal(validateCorrection({ ...base, message: "a".repeat(2001) }).ok, false);
  assert.equal(validateCorrection({ ...base, message: "a".repeat(2000) }).ok, true);
});

test("refuse une URL de source qui n'est pas http(s)", () => {
  assert.equal(validateCorrection({ ...base, source_url: "javascript:alert(1)" }).ok, false);
  assert.equal(validateCorrection({ ...base, source_url: "nestle.com" }).ok, false);
  assert.equal(validateCorrection({ ...base, source_url: "https://nestle.com/x" }).ok, true);
});

test("refuse une entité manquante", () => {
  assert.equal(validateCorrection({ ...base, entity_slug: "" }).ok, false);
  assert.equal(validateCorrection({ ...base, entity_slug: "a".repeat(121) }).ok, false);
});

test("refuse un contact ou un indicateur hors bornes", () => {
  assert.equal(validateCorrection({ ...base, contact: "a".repeat(201) }).ok, false);
  assert.equal(validateCorrection({ ...base, indicator_code: "a".repeat(61) }).ok, false);
});
