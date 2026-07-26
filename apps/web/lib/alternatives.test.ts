// Tests de la sélection d'alternatives (logique pure).
// Lancer : node --test --experimental-strip-types apps/web/lib/alternatives.test.ts
import { test } from "node:test";
import assert from "node:assert/strict";
import {
  pickComparable,
  selectAlternatives,
  type ScoredCandidate,
} from "./alternatives.ts";

const rows = [
  { slug: "ben-jerrys", is_brand: true, sector_id: "food" },
  { slug: "alpro", is_brand: true, sector_id: "food" },
  { slug: "danone", is_brand: false, sector_id: "fmcg_group" },
  { slug: "nestle", is_brand: false, sector_id: "fmcg_group" },
  { slug: "gucci", is_brand: true, sector_id: "fashion" },
  { slug: "orphan", is_brand: true, sector_id: null },
];

test("ne compare qu'à secteur ET nature identiques", () => {
  const got = pickComparable(rows, rows[0]).map((e) => e.slug);
  assert.deepEqual(got, ["alpro"]); // ni Danone (groupe), ni Gucci (autre secteur)
});

test("un groupe n'est comparé qu'à des groupes", () => {
  const got = pickComparable(rows, rows[3]).map((e) => e.slug);
  assert.deepEqual(got, ["danone"]);
});

test("une entité sans secteur n'est comparable à rien", () => {
  assert.deepEqual(pickComparable(rows, rows[5]), []);
});

test("une entité ne se compare jamais à elle-même", () => {
  assert.ok(!pickComparable(rows, rows[1]).some((e) => e.slug === "alpro"));
});

const cand = (over: Partial<ScoredCandidate>): ScoredCandidate => ({
  slug: "x",
  name: "X",
  grade: "B",
  score: 0.7,
  confidence: 0.6,
  publishable: true,
  root: null,
  ...over,
});

test("écarte toute alternative non publiable, même mieux notée", () => {
  const out = selectAlternatives(
    [cand({ slug: "opaque", score: 0.95, publishable: false })],
    0.4,
    null,
  );
  assert.deepEqual(out, []);
});

test("n'garde que les notes strictement supérieures", () => {
  const out = selectAlternatives(
    [
      cand({ slug: "egal", score: 0.5 }),
      cand({ slug: "pire", score: 0.3 }),
      cand({ slug: "mieux", score: 0.62 }),
    ],
    0.5,
    null,
  );
  assert.deepEqual(out.map((a) => a.slug), ["mieux"]);
});

test("trie par note décroissante et calcule le delta", () => {
  const out = selectAlternatives(
    [
      cand({ slug: "b", score: 0.6 }),
      cand({ slug: "a", score: 0.8 }),
      cand({ slug: "c", score: 0.7 }),
    ],
    0.5,
    null,
  );
  assert.deepEqual(out.map((a) => a.slug), ["a", "c", "b"]);
  assert.ok(Math.abs(out[0].delta - 0.3) < 1e-9);
});

test("à note égale, tri alphabétique (résultat déterministe)", () => {
  const out = selectAlternatives(
    [cand({ slug: "z", name: "Zeta" }), cand({ slug: "a", name: "Alpha" })],
    0.5,
    null,
  );
  assert.deepEqual(out.map((a) => a.name), ["Alpha", "Zeta"]);
});

test("borne le nombre de résultats", () => {
  const many = Array.from({ length: 10 }, (_, i) =>
    cand({ slug: `s${i}`, name: `S${i}`, score: 0.6 + i / 100 }),
  );
  assert.equal(selectAlternatives(many, 0.5, null).length, 4);
  assert.equal(selectAlternatives(many, 0.5, null, 2).length, 2);
});

test("signale une alternative du même groupe propriétaire", () => {
  const out = selectAlternatives(
    [
      cand({ slug: "cousine", score: 0.7, root: "nestle" }),
      cand({ slug: "rivale", score: 0.75, root: "danone" }),
    ],
    0.5,
    "nestle",
  );
  assert.equal(out.find((a) => a.slug === "cousine")!.same_group, true);
  assert.equal(out.find((a) => a.slug === "rivale")!.same_group, false);
});

test("racine inconnue des deux côtés ne vaut pas « même groupe »", () => {
  const out = selectAlternatives([cand({ score: 0.7, root: null })], 0.5, null);
  assert.equal(out[0].same_group, false);
});
