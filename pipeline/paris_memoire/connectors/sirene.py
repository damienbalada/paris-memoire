"""Connecteur SIRENE via l'API publique « Recherche d'entreprises ».

https://recherche-entreprises.api.gouv.fr — open data, sans clé. Fournit le
SIREN et la raison sociale des entreprises françaises.
"""
from __future__ import annotations

from typing import Any

import httpx

RECHERCHE_BASE = "https://recherche-entreprises.api.gouv.fr"


def parse_result(res: dict[str, Any]) -> dict[str, Any]:
    """Extrait {siren, nom} d'un résultat brut."""
    return {
        "siren": res.get("siren"),
        "nom": res.get("nom_complet") or res.get("nom_raison_sociale"),
    }


def search_siren(name: str, client: httpx.Client | None = None) -> list[dict[str, Any]]:
    """Recherche d'entreprises françaises par nom."""
    c = client or httpx.Client(timeout=20)
    try:
        r = c.get(f"{RECHERCHE_BASE}/search", params={"q": name, "per_page": 5})
        r.raise_for_status()
        return [parse_result(x) for x in r.json().get("results", [])]
    finally:
        if client is None:
            c.close()
