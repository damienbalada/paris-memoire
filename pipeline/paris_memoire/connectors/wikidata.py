"""Connecteur Wikidata — graphe de propriété marque -> groupe (tous secteurs).

Wikidata expose, via SPARQL (query.wikidata.org), les relations :
  * P127 « propriétaire de » (owned by)
  * P749 « organisation mère » (parent organization)
  * P1830 / P155… selon les cas.

Ce module fournit la requête SPARQL et le parseur du JSON de réponse. L'appel
réseau lui-même est à activer une fois `query.wikidata.org` autorisé.
"""
from __future__ import annotations

from dataclasses import dataclass

WIKIDATA_SPARQL_URL = "https://query.wikidata.org/sparql"

# Remonte le propriétaire / la maison mère d'une marque donnée par son libellé.
# Conservateur : on renvoie le libellé du propriétaire, le matching final se fait
# ensuite contre nos groupes via resolve_brands (pas de rattachement à l'aveugle).
SPARQL_OWNER_BY_BRAND = """
SELECT ?brand ?brandLabel ?owner ?ownerLabel WHERE {
  ?brand rdfs:label ?brandLabel .
  FILTER(LANG(?brandLabel) = "fr" || LANG(?brandLabel) = "en")
  FILTER(LCASE(STR(?brandLabel)) = LCASE("%s"))
  OPTIONAL { ?brand wdt:P127 ?owner. }
  OPTIONAL { ?brand wdt:P749 ?owner. }
  SERVICE wikibase:label { bd:serviceParam wikibase:language "fr,en". }
}
LIMIT 5
"""


@dataclass
class WikidataOwner:
    brand_label: str
    owner_label: str | None


def parse_owner_response(payload: dict) -> WikidataOwner | None:
    """Extrait (marque, propriétaire) du JSON SPARQL. None si vide."""
    rows = (payload.get("results") or {}).get("bindings") or []
    for row in rows:
        owner = (row.get("ownerLabel") or {}).get("value")
        brand = (row.get("brandLabel") or {}).get("value")
        if brand:
            return WikidataOwner(brand_label=brand, owner_label=owner or None)
    return None
