import { getSupabase } from "./supabase";
import type { ScoreInput } from "./scoring";

export interface ScorePayload extends ScoreInput {
  entity: { slug: string; name: string; sector_id: string | null };
  ownership_chain: string[];
  profile: { code: string; name: string };
}

export interface ProfilePreset {
  code: string;
  name: string;
  weights: Record<string, number>;
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

/** Profils de pondération + leurs poids (pour les presets des sliders). */
export async function getProfilePresets(): Promise<ProfilePreset[]> {
  const supabase = getSupabase();
  const { data, error } = await supabase
    .from("value_profiles")
    .select("code, name, is_default, profile_weights(weight, dimensions(code))")
    .order("is_default", { ascending: false });
  if (error) throw new Error(error.message);
  return (data ?? []).map((p: any) => ({
    code: p.code,
    name: p.name,
    weights: Object.fromEntries(
      (p.profile_weights ?? [])
        .filter((w: any) => w.dimensions)
        .map((w: any) => [w.dimensions.code, Number(w.weight)]),
    ),
  }));
}
