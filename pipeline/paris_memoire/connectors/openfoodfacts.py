"""Connecteur Open Food Facts — univers des marques de grande conso.

Open Food Facts (world.openfoodfacts.org) est une base OUVERTE et téléchargeable
(dumps CSV/JSONL, API) recensant les produits vendus en France/Europe, avec
marque (`brands`), propriétaire (`brands_tags` / `owner`), catégories et pays.
Ses cousins couvrent le reste : Open Beauty Facts, Open Products Facts,
Open Pet Food Facts.

Ce module NE FAIT PAS d'appel réseau ici (domaine à autoriser d'abord). Il
fournit :
  * le mapping catégorie OFF -> secteur DIAMS,
  * l'agrégation produits -> marques (avec popularité = nb de produits),
produisant des `StagingBrand` prêts pour la table `staging_brands`.
"""
from __future__ import annotations

from collections import Counter, defaultdict
from dataclasses import dataclass, field
from typing import Iterable

# Dumps officiels (à ingérer une fois le domaine autorisé) :
#   https://static.openfoodfacts.org/data/openfoodfacts-products.jsonl.gz
#   https://world.openfoodfacts.org/api/v2/... (API produit/facette)
OFF_DUMP_URL = "https://static.openfoodfacts.org/data/openfoodfacts-products.jsonl.gz"

# Catégorie OFF (préfixe de tag) -> code secteur DIAMS. Ordre = priorité.
SECTOR_BY_OFF_CATEGORY: list[tuple[str, str]] = [
    ("en:pet-food", "pet_care"),
    ("en:petfood", "pet_care"),
    ("en:beverages", "beverages"),
    ("en:waters", "beverages"),
    ("en:alcoholic-beverages", "wines_spirits"),
    ("en:wines", "wines_spirits"),
    ("en:beers", "beverages"),
    ("en:hygiene", "personal_care"),
    ("en:cleaning", "home_care"),
    ("en:beauty", "beauty_fragrance"),
    ("en:cosmetics", "beauty_fragrance"),
    ("en:foods", "food"),
]


def map_sector(categories_tags: Iterable[str] | None) -> str | None:
    """Déduit un secteur DIAMS depuis les tags catégorie OFF. None si inconnu."""
    tags = list(categories_tags or [])
    for prefix, sector in SECTOR_BY_OFF_CATEGORY:
        if any(t == prefix or t.startswith(prefix) for t in tags):
            return sector
    # Par défaut, un produit OFF est alimentaire.
    return "food" if tags else None


@dataclass
class StagingBrand:
    source: str
    source_ref: str          # tag marque OFF (slug stable), ex: "coca-cola"
    name: str
    owner_raw: str | None
    sector_guess: str | None
    country: str | None
    product_count: int
    payload: dict = field(default_factory=dict)


def _first(rec: dict, *keys: str):
    for k in keys:
        v = rec.get(k)
        if v:
            return v
    return None


def brands_from_products(
    products: Iterable[dict], source: str = "openfoodfacts"
) -> list[StagingBrand]:
    """Agrège des enregistrements produit OFF en marques (popularité = nb produits).

    Chaque produit OFF porte typiquement : `brands_tags` (liste de slugs),
    `brands` (libellé), `owner`/`brand_owner`, `categories_tags`, `countries_tags`.
    """
    names: dict[str, Counter] = defaultdict(Counter)
    owners: dict[str, Counter] = defaultdict(Counter)
    sectors: dict[str, Counter] = defaultdict(Counter)
    countries: dict[str, Counter] = defaultdict(Counter)
    counts: Counter = Counter()

    for p in products:
        tags = p.get("brands_tags") or []
        if not tags:
            continue
        label = _first(p, "brands") or ""
        labels = [s.strip() for s in label.split(",") if s.strip()]
        owner = _first(p, "brand_owner", "owner")
        sector = map_sector(p.get("categories_tags"))
        ctys = p.get("countries_tags") or []
        for i, tag in enumerate(tags):
            counts[tag] += 1
            if i < len(labels):
                names[tag][labels[i]] += 1
            if owner:
                owners[tag][owner] += 1
            if sector:
                sectors[tag][sector] += 1
            for c in ctys:
                countries[tag][c] += 1

    out: list[StagingBrand] = []
    for tag, n in counts.items():
        name = names[tag].most_common(1)[0][0] if names[tag] else tag.replace("-", " ").title()
        owner = owners[tag].most_common(1)[0][0] if owners[tag] else None
        sector = sectors[tag].most_common(1)[0][0] if sectors[tag] else None
        country = countries[tag].most_common(1)[0][0] if countries[tag] else None
        out.append(StagingBrand(
            source=source, source_ref=tag, name=name, owner_raw=owner,
            sector_guess=sector, country=country, product_count=n,
        ))
    out.sort(key=lambda b: b.product_count, reverse=True)
    return out
