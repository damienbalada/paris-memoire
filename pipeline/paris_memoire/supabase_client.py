"""Accès Supabase via l'API REST (PostgREST), en service_role.

La service_role contourne la RLS : réservée au back-office / pipeline, jamais
exposée côté navigateur.
"""
from __future__ import annotations

from typing import Any

import httpx

from . import config


def _headers() -> dict[str, str]:
    return {
        "apikey": config.SUPABASE_SERVICE_ROLE_KEY,
        "Authorization": f"Bearer {config.SUPABASE_SERVICE_ROLE_KEY}",
        "Content-Type": "application/json",
    }


def list_entities(client: httpx.Client | None = None) -> list[dict[str, Any]]:
    """Toutes les entités avec leurs identifiants actuels."""
    config.require_supabase()
    c = client or httpx.Client(timeout=30)
    try:
        r = c.get(
            f"{config.SUPABASE_URL}/rest/v1/entities",
            params={"select": "id,slug,legal_name,display_name,country,lei,siren,is_brand"},
            headers=_headers(),
        )
        r.raise_for_status()
        return r.json()
    finally:
        if client is None:
            c.close()


def update_entity(entity_id: str, fields: dict[str, Any], client: httpx.Client | None = None) -> None:
    """Met à jour une entité (ex: {'lei': ..., 'siren': ...})."""
    config.require_supabase()
    c = client or httpx.Client(timeout=30)
    try:
        r = c.patch(
            f"{config.SUPABASE_URL}/rest/v1/entities",
            params={"id": f"eq.{entity_id}"},
            headers={**_headers(), "Prefer": "return=minimal"},
            json=fields,
        )
        r.raise_for_status()
    finally:
        if client is None:
            c.close()
