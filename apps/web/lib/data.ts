import { getSupabase } from "./supabase";
import { computeScore, type ScoreInput } from "./scoring";

export interface ScorePayload extends ScoreInput {
  entity: { slug: string; name: string; sector_id: string | null };
  ownership_chain: string[];
  profile: { code: string; name: string };
}

/** Assemble les entrées de scoring d'une entité via la fonction SQL. */
export async function getScorePayload(
  slug: string,
  profile = "equilibre",
): Promise<ScorePayload | null> {
  const supabase = getSupabase();
  const { data, error } = await supabase.rpc("compute_score_input", {
    p_slug: slug,
    p_profile: profile,
  });
  if (error) throw new Error(error.message);
  if (!data || !data.entity) return null;
  return data as ScorePayload;
}

export interface EntityScore {
  slug: string;
  name: string;
  is_brand: boolean;
  group: string | null;
  grade: string;
  score: number;
  confidence: number;
  publishable: boolean;
  last_observed: string | null;
}

async function mapWithConcurrency<T, R>(items: T[], limit: number, fn: (t: T) => Promise<R>): Promise<R[]> {
  const out: R[] = [];
  for (let i = 0; i < items.length; i += limit) {
    const batch = items.slice(i, i + limit);
    out.push(...(await Promise.all(batch.map(fn))));
  }
  return out;
}

/** Calcule la note de toutes les entités (pour classement + accueil). */
export async function getAllScores(): Promise<EntityScore[]> {
  const entities = await listEntities();
  const scored = await mapWithConcurrency(entities, 6, async (e: any) => {
    try {
      const payload = await getScorePayload(e.slug);
      if (!payload) return null;
      const r = computeScore(payload);
      const chain = payload.ownership_chain ?? [];
      return {
        slug: e.slug,
        name: e.display_name ?? e.legal_name,
        is_brand: e.is_brand,
        group: chain.length > 1 ? chain[chain.length - 1] : null,
        grade: r.grade,
        score: r.score,
        confidence: r.confidence,
        publishable: r.publishable,
        last_observed: r.last_observed,
      } as EntityScore;
    } catch {
      return null;
    }
  });
  return scored.filter((x): x is EntityScore => x !== null);
}

/** Liste des entités pour la page d'accueil. */
export async function listEntities() {
  const supabase = getSupabase();
  const { data, error } = await supabase
    .from("entities")
    .select("slug, display_name, legal_name, is_brand, parent_id")
    .order("is_brand")
    .order("display_name");
  if (error) throw new Error(error.message);
  return data ?? [];
}

// --- Module civique : cartographie des votes des groupes politiques ----------

export interface CivicGroup { code: string; short_name: string; name: string; ordinal: number }
export interface CivicPosition {
  group_code: string;
  stance: "for" | "against" | "split" | "abstain";
  n_for: number | null;
  n_against: number | null;
  n_abstain: number | null;
  note: string | null;
}
export interface CivicVote {
  code: string;
  title: string;
  vote_date: string;
  pillar_code: string;
  chamber: string;
  source_url: string;
  alignment_note: string | null;
  total_for: number | null;
  total_against: number | null;
  total_abstain: number | null;
  positions: CivicPosition[];
}

/** Votes civiques (groupes politiques) + positions, groupés par vote. */
export async function getCivicData(): Promise<{ groups: CivicGroup[]; votes: CivicVote[] }> {
  const supabase = getSupabase();
  const [{ data: groups }, { data: votes }, { data: positions }] = await Promise.all([
    supabase.from("political_groups").select("code, short_name, name, ordinal").order("ordinal"),
    supabase.from("civic_votes").select("id, code, title, vote_date, pillar_code, chamber, source_url, alignment_note, total_for, total_against, total_abstain").order("vote_date", { ascending: false }),
    supabase.from("civic_positions").select("vote_id, group_id, stance, n_for, n_against, n_abstain, note"),
  ]);
  // On relie les positions aux groupes via une requête légère id -> code.
  const { data: groupIds } = await supabase.from("political_groups").select("id, code");
  const codeById = new Map((groupIds ?? []).map((g: any) => [g.id, g.code]));
  const voteById = new Map((votes ?? []).map((v: any) => [v.id, v]));
  const posByVote = new Map<string, CivicPosition[]>();
  for (const p of positions ?? []) {
    const v = voteById.get((p as any).vote_id);
    if (!v) continue;
    const arr = posByVote.get(v.code) ?? [];
    arr.push({
      group_code: codeById.get((p as any).group_id) ?? "",
      stance: (p as any).stance,
      n_for: (p as any).n_for ?? null,
      n_against: (p as any).n_against ?? null,
      n_abstain: (p as any).n_abstain ?? null,
      note: (p as any).note ?? null,
    });
    posByVote.set(v.code, arr);
  }
  const outVotes: CivicVote[] = (votes ?? []).map((v: any) => ({
    code: v.code, title: v.title, vote_date: v.vote_date, pillar_code: v.pillar_code,
    chamber: v.chamber, source_url: v.source_url, alignment_note: v.alignment_note,
    total_for: v.total_for, total_against: v.total_against, total_abstain: v.total_abstain,
    positions: posByVote.get(v.code) ?? [],
  }));
  const outGroups: CivicGroup[] = (groups ?? []).map((g: any) => ({
    code: g.code, short_name: g.short_name, name: g.name, ordinal: g.ordinal,
  }));
  return { groups: outGroups, votes: outVotes };
}

/**
 * Remonte la chaîne de propriété jusqu'au groupe racine (le vrai bénéficiaire
 * économique). Renvoie null si l'entité est elle-même la racine.
 */
export async function getOwnerGroup(slug: string): Promise<{ slug: string; name: string } | null> {
  const supabase = getSupabase();
  const { data, error } = await supabase
    .from("entities")
    .select("id, slug, display_name, legal_name, parent_id");
  if (error || !data) return null;
  const byId = new Map<string, any>(data.map((e: any) => [e.id, e]));
  const bySlug = new Map<string, any>(data.map((e: any) => [e.slug, e]));
  let cur = bySlug.get(slug);
  if (!cur) return null;
  while (cur.parent_id && byId.get(cur.parent_id)) cur = byId.get(cur.parent_id);
  if (!cur || cur.slug === slug) return null; // l'entité est déjà la racine
  return { slug: cur.slug, name: cur.display_name ?? cur.legal_name };
}
