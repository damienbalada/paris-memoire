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
