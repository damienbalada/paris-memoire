/**
 * Signalements de correction — validation pure (aucun accès base, testable).
 *
 * Un signalement n'est PAS une preuve : il n'entre jamais dans un score. Il
 * ouvre une file de revue humaine, et s'il est retenu il doit être converti en
 * `evidence` avec sa propre source et son propre tier.
 */

export const CORRECTION_KINDS = {
  missing: "Donnée manquante",
  wrong: "Donnée fausse ou mal interprétée",
  dead_link: "Lien de source cassé",
  other: "Autre",
} as const;

export type CorrectionKind = keyof typeof CORRECTION_KINDS;

export interface CorrectionInput {
  entity_slug: string;
  indicator_code: string | null;
  kind: CorrectionKind;
  message: string;
  source_url: string | null;
  contact: string | null;
}

export type Validation =
  | { ok: true; value: CorrectionInput }
  | { ok: false; error: string };

const MESSAGE_MIN = 10;
const MESSAGE_MAX = 2000;

/** Chaîne nettoyée, ou null si vide (on n'insère pas de chaînes vides). */
function trimmed(v: unknown): string | null {
  if (typeof v !== "string") return null;
  const s = v.trim();
  return s.length > 0 ? s : null;
}

/**
 * Valide une soumission de formulaire. Les bornes reproduisent les contraintes
 * CHECK de la table : la base reste l'autorité, ce contrôle sert à rendre
 * l'erreur lisible au lieu d'une violation de contrainte.
 */
export function validateCorrection(raw: Record<string, unknown>): Validation {
  const entity_slug = trimmed(raw.entity_slug);
  if (!entity_slug || entity_slug.length > 120) {
    return { ok: false, error: "Entité manquante." };
  }

  const kindRaw = trimmed(raw.kind);
  if (!kindRaw || !(kindRaw in CORRECTION_KINDS)) {
    return { ok: false, error: "Précisez le type de signalement." };
  }
  const kind = kindRaw as CorrectionKind;

  const message = trimmed(raw.message);
  if (!message || message.length < MESSAGE_MIN) {
    return {
      ok: false,
      error: `Décrivez le problème en ${MESSAGE_MIN} caractères au minimum.`,
    };
  }
  if (message.length > MESSAGE_MAX) {
    return { ok: false, error: `Message trop long (${MESSAGE_MAX} caractères maximum).` };
  }

  const source_url = trimmed(raw.source_url);
  if (source_url && !/^https?:\/\/\S+$/.test(source_url)) {
    return { ok: false, error: "L'URL de source doit commencer par http:// ou https://" };
  }

  const contact = trimmed(raw.contact);
  if (contact && contact.length > 200) {
    return { ok: false, error: "Contact trop long." };
  }

  const indicator_code = trimmed(raw.indicator_code);
  if (indicator_code && indicator_code.length > 60) {
    return { ok: false, error: "Code d'indicateur invalide." };
  }

  return {
    ok: true,
    value: { entity_slug, indicator_code, kind, message, source_url, contact },
  };
}
