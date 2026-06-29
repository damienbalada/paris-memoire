"""Connecteur GLEIF (Global Legal Entity Identifier Foundation).

API publique, sans authentification : https://api.gleif.org/api/v1
Fournit le LEI, le nom légal, le pays, et les relations de détention
(parent direct), utiles pour la résolution d'entités.
"""
from __future__ import annotations

from typing import Any

import httpx

GLEIF_BASE = "https://api.gleif.org/api/v1"


def parse_lei_record(rec: dict[str, Any]) -> dict[str, Any]:
    """Extrait {lei, legal_name, country} d'un enregistrement LEI brut."""
    attr = rec.get("attributes", {}) or {}
    entity = attr.get("entity", {}) or {}
    legal_name = (entity.get("legalName") or {}).get("name")
    country = (entity.get("legalAddress") or {}).get("country")
    return {
        "lei": attr.get("lei") or rec.get("id"),
        "legal_name": legal_name,
        "country": country,
    }


def search_lei(name: str, country: str | None = None, client: httpx.Client | None = None) -> list[dict[str, Any]]:
    """Recherche d'enregistrements LEI par nom légal (option : pays ISO-2)."""
    params: dict[str, Any] = {"filter[entity.legalName]": name, "page[size]": 5}
    if country:
        params["filter[entity.legalAddress.country]"] = country
    c = client or httpx.Client(timeout=20)
    try:
        r = c.get(f"{GLEIF_BASE}/lei-records", params=params)
        r.raise_for_status()
        return [parse_lei_record(x) for x in r.json().get("data", [])]
    finally:
        if client is None:
            c.close()


def direct_parent(lei: str, client: httpx.Client | None = None) -> dict[str, Any] | None:
    """Parent direct (relation de détention >50%) d'un LEI, si déclaré."""
    c = client or httpx.Client(timeout=20)
    try:
        r = c.get(f"{GLEIF_BASE}/lei-records/{lei}/direct-parent")
        if r.status_code == 404:
            return None
        r.raise_for_status()
        data = r.json().get("data")
        return parse_lei_record(data) if data else None
    except httpx.HTTPStatusError:
        return None
    finally:
        if client is None:
            c.close()
