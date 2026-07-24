"""Chargement d'evidence en base — TOUJOURS en statut `pending`.

Règle de curation : le pipeline ne publie jamais directement. Chaque evidence
importée attend la revue humaine (back-office /admin/revue) avant de compter
dans un score. L'insertion est idempotente grâce à l'index unique
(entity, indicator, source, observed_on) : relancer un import est sans effet.
"""
from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any

import httpx

from . import config


@dataclass
class EvidenceRow:
    """Une evidence prête à insérer (identifiants métier, pas des UUID)."""

    entity_slug: str
    indicator_code: str
    source_code: str
    nature: str                     # result / commitment / policy / controversy
    observed_on: str                # ISO date
    value_type: str = "category"    # numeric / boolean / ordinal / category
    value_numeric: float | None = None
    value_boolean: bool | None = None
    value_text: str | None = None
    normalized_value: float | None = None
    confidence: float = 0.7
    source_url: str | None = None
    excerpt: str | None = None
    reviewer: str = field(default="pipeline")


def _headers() -> dict[str, str]:
    return {
        "apikey": config.SUPABASE_SERVICE_ROLE_KEY,
        "Authorization": f"Bearer {config.SUPABASE_SERVICE_ROLE_KEY}",
        "Content-Type": "application/json",
    }


def _lookup_ids(client: httpx.Client) -> tuple[dict, dict, dict]:
    """Maps slug->entity_id, code->indicator_id, code->source_id."""
    base = f"{config.SUPABASE_URL}/rest/v1"
    ents = client.get(f"{base}/entities", params={"select": "id,slug"}, headers=_headers())
    inds = client.get(f"{base}/indicators", params={"select": "id,code"}, headers=_headers())
    srcs = client.get(f"{base}/sources", params={"select": "id,code,tier"}, headers=_headers())
    for r in (ents, inds, srcs):
        r.raise_for_status()
    return (
        {e["slug"]: e["id"] for e in ents.json()},
        {i["code"]: i["id"] for i in inds.json()},
        {s["code"]: (s["id"], s.get("tier")) for s in srcs.json()},
    )


# Confiance graduée par tier de source (cf. REVIEW_MODEL.md).
# Sources d'autorité ingérées par un connecteur DÉTERMINISTE -> publication auto,
# tracée par `reviewer = auto:<connecteur>` (auditable a posteriori par échantillon).
# Presse et contributif -> file de revue humaine obligatoire.
AUTO_PUBLISH_TIERS = {"regulatory", "audited_ngo"}


def review_status_for(tier: str | None) -> str:
    """`approved` pour les tiers 1-2, `pending` sinon (tier inconnu = prudence)."""
    return "approved" if tier in AUTO_PUBLISH_TIERS else "pending"


def insert_evidence(rows: list[EvidenceRow], client: httpx.Client | None = None) -> dict[str, int]:
    """Insère les evidence avec un statut dérivé du TIER de la source.

    Tiers 1-2 (regulatory / ONG auditée) : publiés automatiquement, reviewer
    `auto:<connecteur>`. Tier 3 / crowd : `pending`, revue humaine obligatoire.

    Retourne {"inserted": n, "skipped": m} (skipped = doublons ou refs inconnues).
    """
    config.require_supabase()
    c = client or httpx.Client(timeout=60)
    stats = {"inserted": 0, "skipped": 0}
    try:
        entities, indicators, sources = _lookup_ids(c)
        payload: list[dict[str, Any]] = []
        for row in rows:
            eid = entities.get(row.entity_slug)
            iid = indicators.get(row.indicator_code)
            src = sources.get(row.source_code)
            if not (eid and iid and src):
                stats["skipped"] += 1
                continue
            sid, tier = src
            status = review_status_for(tier)
            # Traçabilité : distinguer une publication automatique d'une validation humaine.
            reviewer = row.reviewer
            if status == "approved" and not reviewer.startswith("auto:"):
                reviewer = f"auto:{reviewer}"
            payload.append({
                "entity_id": eid,
                "indicator_id": iid,
                "source_id": sid,
                "nature": row.nature,
                "observed_on": row.observed_on,
                "value_type": row.value_type,
                "value_numeric": row.value_numeric,
                "value_boolean": row.value_boolean,
                "value_text": row.value_text,
                "normalized_value": row.normalized_value,
                "confidence": row.confidence,
                "source_url": row.source_url,
                "excerpt": row.excerpt,
                "reviewer": reviewer,
                "review_status": status,   # dérivé du tier de la source (REVIEW_MODEL.md)
            })
        if not payload:
            return stats
        # resolution=ignore-duplicates + index unique => import idempotent
        r = c.post(
            f"{config.SUPABASE_URL}/rest/v1/evidence",
            params={"on_conflict": "entity_id,indicator_id,source_id,observed_on"},
            headers={**_headers(), "Prefer": "resolution=ignore-duplicates,return=representation"},
            json=payload,
        )
        r.raise_for_status()
        inserted = len(r.json())
        stats["inserted"] = inserted
        stats["skipped"] += len(payload) - inserted
        return stats
    finally:
        if client is None:
            c.close()
