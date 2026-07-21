"""Résolution marque -> groupe propriétaire (logique PURE, testable).

But : rattacher une marque ingérée (Open Food Facts) à un GROUPE déjà présent
dans DIAMS, pour qu'elle hérite de ses preuves ESG. On ne DEVINE jamais : en
l'absence de correspondance nette, on renvoie `none` -> file de revue humaine.

Sources de rattachement, par ordre de confiance :
  1. off_owner   : le `brand_owner` d'Open Food Facts matche un groupe existant.
  2. wikidata    : Wikidata donne un propriétaire qui matche un groupe existant.
  3. name_group  : la marque est éponyme d'un groupe existant (ex : « Danone »).
  4. none        : aucune correspondance -> revue manuelle.
"""
from __future__ import annotations

from dataclasses import dataclass

from .normalize.names import is_strong_match


@dataclass
class Resolution:
    group_slug: str | None
    method: str            # off_owner | wikidata | name_group | none
    confidence: float
    note: str = ""


def _match_group(query: str | None, entities: list[dict]) -> dict | None:
    """1er GROUPE (is_brand=False) dont le nom/alias matche nettement `query`."""
    if not query:
        return None
    for e in entities:
        if e.get("is_brand"):
            continue
        names = [e.get("name") or "", *(e.get("aliases") or [])]
        if any(is_strong_match(query, n) for n in names):
            return e
    return None


def resolve(
    *, brand_name: str, owner_raw: str | None, entities: list[dict],
    wikidata_owner: str | None = None,
) -> Resolution:
    """Propose un rattachement. `entities` : [{slug, name, is_brand, aliases}]."""
    # 1) propriétaire déclaré par Open Food Facts
    g = _match_group(owner_raw, entities)
    if g:
        return Resolution(g["slug"], "off_owner", 0.82,
                          f"brand_owner OFF « {owner_raw} » → {g['slug']}")

    # 2) propriétaire d'après Wikidata
    g = _match_group(wikidata_owner, entities)
    if g:
        return Resolution(g["slug"], "wikidata", 0.75,
                          f"propriétaire Wikidata « {wikidata_owner} » → {g['slug']}")

    # 3) marque éponyme d'un groupe (ex : « Danone », « Nestlé »)
    g = _match_group(brand_name, entities)
    if g:
        return Resolution(g["slug"], "name_group", 0.90,
                          f"marque éponyme du groupe {g['slug']}")

    # 4) aucune correspondance nette : on ne devine pas
    return Resolution(None, "none", 0.0, "aucune correspondance — revue manuelle")
