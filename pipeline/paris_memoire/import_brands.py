"""Orchestrateur : univers des marques -> file de revue de rattachement.

Flux (à activer une fois les domaines autorisés : world/static.openfoodfacts.org,
query.wikidata.org) :

  1. Charger un dump Open Food Facts (JSONL) -> agréger en marques.
  2. Filtrer (marché FR/UE, popularité minimale) pour éviter le bruit de la longue traîne.
  3. Upsert dans `staging_brands`.
  4. Charger nos entités + alias.
  5. Résoudre chaque marque -> groupe (off_owner > wikidata > éponymie), sinon `none`.
  6. Écrire les propositions dans `brand_resolutions` (status=pending) -> revue humaine.

Rien n'entre dans `entities` ici : la création des marques rattachées se fait à
l'APPROBATION dans le back-office (/admin), jamais automatiquement.
"""
from __future__ import annotations

import gzip
import json
from typing import Iterable

import httpx

from . import config
from .connectors.openfoodfacts import StagingBrand, brands_from_products
from .normalize.names import normalize_name
from .resolve_brands import resolve

MIN_PRODUCTS = 5          # ignore la longue traîne peu fiable
KEEP_COUNTRIES = {"en:france", "en:european-union"}


def read_off_jsonl(path: str) -> Iterable[dict]:
    """Lit un dump OFF .jsonl(.gz) ligne à ligne (peu de mémoire)."""
    opener = gzip.open if path.endswith(".gz") else open
    with opener(path, "rt", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if line:
                yield json.loads(line)


def select_brands(brands: list[StagingBrand]) -> list[StagingBrand]:
    """Garde le marché FR/UE et les marques assez présentes."""
    return [
        b for b in brands
        if b.product_count >= MIN_PRODUCTS
        and (b.country in KEEP_COUNTRIES or b.country is None)
    ]


def load_entities_with_aliases(client: httpx.Client) -> list[dict]:
    """Entités + alias, au format attendu par resolve()."""
    config.require_supabase()
    h = {"apikey": config.SUPABASE_SERVICE_ROLE_KEY,
         "Authorization": f"Bearer {config.SUPABASE_SERVICE_ROLE_KEY}"}
    ents = client.get(f"{config.SUPABASE_URL}/rest/v1/entities",
                      params={"select": "id,slug,display_name,legal_name,is_brand"},
                      headers=h).json()
    aliases = client.get(f"{config.SUPABASE_URL}/rest/v1/entity_aliases",
                         params={"select": "entity_id,alias"}, headers=h).json()
    by_id: dict[str, list[str]] = {}
    for a in aliases:
        by_id.setdefault(a["entity_id"], []).append(a["alias"])
    return [{
        "slug": e["slug"],
        "name": e.get("display_name") or e.get("legal_name"),
        "is_brand": e["is_brand"],
        "aliases": by_id.get(e["id"], []),
    } for e in ents]


def run(dump_path: str) -> dict[str, int]:
    """Exécute le pipeline complet. Renvoie un compte par méthode de résolution."""
    config.require_supabase()
    brands = select_brands(brands_from_products(read_off_jsonl(dump_path)))
    stats: dict[str, int] = {}
    with httpx.Client(timeout=60) as client:
        entities = load_entities_with_aliases(client)
        h = {"apikey": config.SUPABASE_SERVICE_ROLE_KEY,
             "Authorization": f"Bearer {config.SUPABASE_SERVICE_ROLE_KEY}",
             "Content-Type": "application/json",
             "Prefer": "resolution=merge-duplicates,return=representation"}
        for b in brands:
            sb = client.post(
                f"{config.SUPABASE_URL}/rest/v1/staging_brands",
                params={"on_conflict": "source,source_ref"},
                headers=h,
                json={"source": b.source, "source_ref": b.source_ref, "name": b.name,
                      "owner_raw": b.owner_raw, "sector_guess": b.sector_guess,
                      "country": b.country, "product_count": b.product_count},
            ).json()[0]
            res = resolve(brand_name=b.name, owner_raw=b.owner_raw, entities=entities)
            client.post(
                f"{config.SUPABASE_URL}/rest/v1/brand_resolutions",
                params={"on_conflict": "staging_brand_id"},
                headers=h,
                json={"staging_brand_id": sb["id"], "brand_name": b.name,
                      "group_slug": res.group_slug, "method": res.method,
                      "confidence": res.confidence, "note": res.note},
            )
            stats[res.method] = stats.get(res.method, 0) + 1
    return stats


if __name__ == "__main__":  # pragma: no cover
    import sys
    if len(sys.argv) != 2:
        print("usage: python -m paris_memoire.import_brands <off_dump.jsonl[.gz]>")
        raise SystemExit(2)
    print(run(sys.argv[1]))
