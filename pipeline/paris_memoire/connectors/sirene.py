"""Connecteur SIRENE via l'API publique Recherche d'entreprises.

https://recherche-entreprises.api.gouv.fr - open data, sans cle. Fournit le
SIREN et la raison sociale des entreprises francaises.
"""
from __future__ import annotations

from typing import Any

import httpx

RECHERCHE_BASE = "https://recherche-entreprises.api.gouv.fr"


def parse_result(res: dict[str, Any]) -> dict[str, Any]:
    """Extrait siren + nom d'un resultat brut."""
    return {
        "siren": res.get("siren"),
        "nom": res.get("nom_complet") or res.get("nom_raison_sociale"),
    }


def search_siren(name: str, client: httpx.Client | None = None) -> list[dict[str, Any]]:
    """Recherche d'entreprises francaises par nom.

    Robuste : une requete trop courte (< 3 caracteres, ex. LU -> 400) ou toute
    erreur HTTP renvoie [] (entite non resolue) plutot que de faire planter le lot.
    """
    q = (name or "").strip()
    if len(q) < 3:
        return []
    c = client or httpx.Client(timeout=20)
    try:
        r = c.get(f"{RECHERCHE_BASE}/search", params={"q": q, "per_page": 5})
        if r.status_code >= 400:
            return []
        return [parse_result(x) for x in r.json().get("results", [])]
    except httpx.HTTPError:
        return []
    finally:
        if client is None:
            c.close()
