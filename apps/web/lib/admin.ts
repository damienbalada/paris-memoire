import "server-only";
import { createClient } from "@supabase/supabase-js";
import type { CorrectionInput } from "./corrections";

// Back-office UNIQUEMENT. Utilise la service_role (contourne la RLS) :
// - variable SERVEUR (pas de préfixe NEXT_PUBLIC_) → jamais envoyée au navigateur ;
// - à n'utiliser qu'en local ou derrière une vraie authentification.
export function getAdminSupabase() {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const key = process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!url || !key) return null;
  return createClient(url, key, { auth: { persistSession: false } });
}

export interface PendingEvidence {
  id: string;
  nature: string;
  observed_on: string;
  value_text: string | null;
  value_numeric: number | null;
  value_boolean: boolean | null;
  normalized_value: number | null;
  confidence: number;
  excerpt: string | null;
  source_url: string | null;
  reviewer: string | null;
  entity: { slug: string; name: string } | null;
  indicator: { code: string; name: string } | null;
  source: { code: string; name: string; tier: string } | null;
}

export async function listPendingEvidence(): Promise<PendingEvidence[]> {
  const supabase = getAdminSupabase();
  if (!supabase) throw new Error("SUPABASE_SERVICE_ROLE_KEY manquante (voir .env.example).");
  const { data, error } = await supabase
    .from("evidence")
    .select(
      `id, nature, observed_on, value_text, value_numeric, value_boolean,
       normalized_value, confidence, excerpt, source_url, reviewer,
       entities(slug, legal_name, display_name),
       indicators(code, name),
       sources(code, name, tier)`,
    )
    .eq("review_status", "pending")
    .order("created_at", { ascending: true })
    .limit(100);
  if (error) throw new Error(error.message);
  return (data ?? []).map((e: any) => ({
    id: e.id,
    nature: e.nature,
    observed_on: e.observed_on,
    value_text: e.value_text,
    value_numeric: e.value_numeric,
    value_boolean: e.value_boolean,
    normalized_value: e.normalized_value,
    confidence: Number(e.confidence),
    excerpt: e.excerpt,
    source_url: e.source_url,
    reviewer: e.reviewer,
    entity: e.entities
      ? { slug: e.entities.slug, name: e.entities.display_name ?? e.entities.legal_name }
      : null,
    indicator: e.indicators ? { code: e.indicators.code, name: e.indicators.name } : null,
    source: e.sources ? { code: e.sources.code, name: e.sources.name, tier: e.sources.tier } : null,
  }));
}

export async function setReviewStatus(
  id: string,
  status: "approved" | "rejected",
  reviewer: string,
): Promise<void> {
  const supabase = getAdminSupabase();
  if (!supabase) throw new Error("SUPABASE_SERVICE_ROLE_KEY manquante.");
  const { error } = await supabase
    .from("evidence")
    .update({ review_status: status, reviewer })
    .eq("id", id)
    .eq("review_status", "pending"); // on ne re-modifie pas une evidence déjà revue
  if (error) throw new Error(error.message);
}

// --- Signalements de correction ----------------------------------------------

/**
 * Enregistre un signalement public.
 *
 * Passe par la `service_role` côté serveur (Server Action) : la table
 * `corrections` reste fermée à la clé `anon`, donc la doctrine RLS du projet
 * — aucune écriture depuis le navigateur — n'est pas relâchée.
 */
export async function insertCorrection(input: CorrectionInput): Promise<void> {
  const supabase = getAdminSupabase();
  if (!supabase) throw new Error("Réception des signalements non configurée sur ce déploiement.");
  const { error } = await supabase.from("corrections").insert({
    entity_slug: input.entity_slug,
    indicator_code: input.indicator_code,
    kind: input.kind,
    message: input.message,
    source_url: input.source_url,
    contact: input.contact,
  });
  if (error) throw new Error(error.message);
}

export interface Correction {
  id: string;
  entity_slug: string;
  indicator_code: string | null;
  kind: string;
  message: string;
  source_url: string | null;
  contact: string | null;
  status: string;
  created_at: string;
}

/** Signalements en attente de traitement (back-office). */
export async function listPendingCorrections(): Promise<Correction[]> {
  const supabase = getAdminSupabase();
  if (!supabase) throw new Error("SUPABASE_SERVICE_ROLE_KEY manquante.");
  const { data, error } = await supabase
    .from("corrections")
    .select("id, entity_slug, indicator_code, kind, message, source_url, contact, status, created_at")
    .eq("status", "pending")
    .order("created_at", { ascending: true })
    .limit(200);
  if (error) throw new Error(error.message);
  return (data ?? []) as Correction[];
}

/**
 * Clôt un signalement. `accepted` ne publie rien : il acte que le signalement
 * est fondé et qu'une evidence sourcée doit être créée par le pipeline ou la
 * curation. La note ne bouge pas tant que cette evidence n'existe pas.
 */
export async function setCorrectionStatus(
  id: string,
  status: "accepted" | "rejected",
  note: string | null = null,
): Promise<void> {
  const supabase = getAdminSupabase();
  if (!supabase) throw new Error("SUPABASE_SERVICE_ROLE_KEY manquante.");
  const { error } = await supabase
    .from("corrections")
    .update({ status, reviewer_note: note })
    .eq("id", id)
    .eq("status", "pending");
  if (error) throw new Error(error.message);
}
