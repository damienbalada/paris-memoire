/**
 * Alternatives mieux notées — logique de sélection pure (aucun accès base).
 *
 * Isolée dans son propre module pour être testable sans réseau, comme le moteur
 * de scoring : les décisions méthodologiques ne doivent jamais dépendre de l'I/O.
 */

export interface Alternative {
  slug: string;
  name: string;
  grade: string;
  score: number;
  confidence: number;
  /** Écart de note, en points de 0-1 (à afficher × 100). */
  delta: number;
  /** L'alternative appartient au même groupe propriétaire : changer de marque
   *  ne change pas le bénéficiaire économique. À signaler, pas à masquer. */
  same_group: boolean;
}

/** Ligne minimale nécessaire au choix des candidats. */
export interface ComparableEntity {
  slug: string;
  is_brand: boolean;
  sector_id: string | null;
}

/** Candidat déjà noté, avant filtrage. */
export interface ScoredCandidate {
  slug: string;
  name: string;
  grade: string;
  score: number;
  confidence: number;
  publishable: boolean;
  /** Slug du groupe racine, ou null si inconnu. */
  root: string | null;
}

/**
 * **Comparaison à périmètre égal.** Un groupe n'est pas une alternative d'achat
 * à une marque, et deux secteurs différents ne sont pas comparables : les
 * indicateurs applicables n'y sont pas les mêmes, donc les notes ne mesurent pas
 * la même chose. Une entité sans secteur n'est comparable à rien.
 */
export function pickComparable<T extends ComparableEntity>(
  rows: T[],
  self: ComparableEntity,
): T[] {
  if (!self.sector_id) return [];
  return rows.filter(
    (e) => e.slug !== self.slug && e.sector_id === self.sector_id && e.is_brand === self.is_brand,
  );
}

/**
 * Filtre, trie et borne les alternatives.
 *
 * Garde-fou central — **jamais de recommandation non publiable.** Une entité
 * sous le seuil de fiabilité (Règle 5) est écartée : suggérer une marque dont
 * on ne sait rien serait pire que ne rien suggérer. C'est précisément le travers
 * des comparateurs qui font passer l'absence de controverse pour une vertu.
 */
export function selectAlternatives(
  candidates: ScoredCandidate[],
  currentScore: number,
  selfRoot: string | null,
  limit = 4,
): Alternative[] {
  return candidates
    .filter((c) => c.publishable && c.score > currentScore)
    .sort((a, b) => b.score - a.score || a.name.localeCompare(b.name, "fr"))
    .slice(0, limit)
    .map((c) => ({
      slug: c.slug,
      name: c.name,
      grade: c.grade,
      score: c.score,
      confidence: c.confidence,
      delta: c.score - currentScore,
      same_group: Boolean(selfRoot && c.root && selfRoot === c.root),
    }));
}
