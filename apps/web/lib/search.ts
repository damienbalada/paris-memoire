/**
 * Recherche d'entités — logique pure (aucun accès base, testable).
 *
 * Le filtrage se fait côté client sur la liste déjà chargée : à ~200 entités
 * c'est instantané et sans requête. À l'échelle du million de marques il faudra
 * une recherche plein texte en base (index trigramme) — voir ROADMAP, Axe C.
 */

export interface SearchableEntity {
  slug: string;
  name: string;
  is_brand: boolean;
  /** Nom du groupe propriétaire, s'il en existe un. */
  group: string | null;
  grade: string | null;
}

/**
 * Forme comparable d'un libellé : minuscules, sans accents, sans ponctuation ni
 * espaces. « L'Oréal » → `loreal`, « Ben & Jerry's » → `benjerrys`.
 *
 * Retirer les espaces est délibéré : on veut que « ben jerry » trouve
 * « Ben & Jerry's », ce qu'une comparaison mot à mot manquerait.
 */
export function normalize(s: string): string {
  return s
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "") // diacritiques
    .toLowerCase()
    .replace(/[^a-z0-9]/g, "");
}

/**
 * Filtre les entités dont le nom, le slug ou le **groupe propriétaire**
 * contient la requête. Inclure le groupe est volontaire : chercher « Unilever »
 * doit remonter ses marques, puisque c'est là que va l'argent.
 *
 * Tri : les correspondances en **début de nom** d'abord (« nes » → Nestlé avant
 * Danone-via-groupe), puis alphabétique — résultat déterministe.
 */
export function searchEntities<T extends SearchableEntity>(items: T[], query: string): T[] {
  const q = normalize(query);
  if (!q) return [];

  const scored: { item: T; rank: number }[] = [];
  for (const item of items) {
    const name = normalize(item.name);
    const slug = normalize(item.slug);
    const group = item.group ? normalize(item.group) : "";

    let rank: number;
    if (name.startsWith(q)) rank = 0;
    else if (name.includes(q) || slug.includes(q)) rank = 1;
    else if (group.includes(q)) rank = 2; // trouvé via son propriétaire
    else continue;

    scored.push({ item, rank });
  }

  return scored
    .sort((a, b) => a.rank - b.rank || a.item.name.localeCompare(b.item.name, "fr"))
    .map((s) => s.item);
}
