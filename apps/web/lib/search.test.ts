// Tests de la recherche d'entités (logique pure).
// Lancer : node --test --experimental-strip-types apps/web/lib/search.test.ts
import { test } from "node:test";
import assert from "node:assert/strict";
import { normalize, searchEntities, type SearchableEntity } from "./search.ts";

const e = (
  name: string,
  slug: string,
  group: string | null = null,
  is_brand = true,
): SearchableEntity => ({ slug, name, is_brand, group, grade: "B" });

const base: SearchableEntity[] = [
  e("Ben & Jerry's", "ben-jerrys", "Unilever"),
  e("L'Oréal Paris", "loreal-paris", "L'Oréal"),
  e("Nestlé", "nestle", null, false),
  e("Danone", "danone", null, false),
  e("Nespresso", "nespresso", "Nestlé"),
  e("Häagen-Dazs", "haagen-dazs", "General Mills"),
];

test("normalize retire accents, ponctuation et espaces", () => {
  assert.equal(normalize("L'Oréal"), "loreal");
  assert.equal(normalize("Ben & Jerry's"), "benjerrys");
  assert.equal(normalize("Häagen-Dazs"), "haagendazs");
  assert.equal(normalize("  NESTLÉ  "), "nestle");
  assert.equal(normalize("!!!"), "");
});

test("une requête vide ou sans lettre ne renvoie rien", () => {
  assert.deepEqual(searchEntities(base, ""), []);
  assert.deepEqual(searchEntities(base, "   "), []);
  assert.deepEqual(searchEntities(base, "&&&"), []);
});

test("trouve malgré les accents, dans les deux sens", () => {
  assert.deepEqual(searchEntities(base, "nestle").map((x) => x.slug)[0], "nestle");
  assert.deepEqual(searchEntities(base, "nestlé").map((x) => x.slug)[0], "nestle");
  assert.deepEqual(searchEntities(base, "haagen").map((x) => x.slug), ["haagen-dazs"]);
});

test("trouve malgré la ponctuation manquante", () => {
  assert.deepEqual(searchEntities(base, "ben jerry").map((x) => x.slug), ["ben-jerrys"]);
  assert.deepEqual(searchEntities(base, "loreal").map((x) => x.slug), ["loreal-paris"]);
});

test("trouve une marque par son groupe propriétaire", () => {
  // « Unilever » n'est pas dans la liste, mais Ben & Jerry's lui appartient.
  assert.deepEqual(searchEntities(base, "unilever").map((x) => x.slug), ["ben-jerrys"]);
});

test("le nom prime sur le groupe dans le classement", () => {
  // « nes » matche Nestlé (début de nom) et Nespresso (début de nom),
  // et Nespresso via son groupe — le nom doit passer devant.
  const out = searchEntities(base, "nestle").map((x) => x.slug);
  assert.equal(out[0], "nestle"); // nom exact avant la marque rattachée
  assert.ok(out.includes("nespresso"));
});

test("préfixe de nom avant correspondance au milieu", () => {
  const items = [e("Alpha Nes", "alpha-nes"), e("Nespresso", "nespresso")];
  assert.deepEqual(searchEntities(items, "nes").map((x) => x.slug), ["nespresso", "alpha-nes"]);
});

test("tri déterministe à rang égal (alphabétique)", () => {
  const items = [e("Zeta", "zeta"), e("Alpha", "alpha")];
  assert.deepEqual(searchEntities(items, "a").map((x) => x.name), ["Alpha", "Zeta"]);
});

test("recherche aussi sur le slug", () => {
  const items = [e("Marque Truc", "yves-rocher")];
  assert.deepEqual(searchEntities(items, "yves").map((x) => x.slug), ["yves-rocher"]);
});

test("aucun doublon quand nom et groupe matchent tous deux", () => {
  const items = [e("Nestlé Waters", "nestle-waters", "Nestlé")];
  assert.equal(searchEntities(items, "nestle").length, 1);
});
