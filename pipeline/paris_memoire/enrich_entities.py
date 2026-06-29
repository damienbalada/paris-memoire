"""Enrichit les entités avec leur LEI (GLEIF) et SIREN (SIRENE).

Remplit les identifiants officiels laissés vides au seed — socle de la
résolution d'entités. Matching CONSERVATEUR : en cas de doute, on n'écrit rien
et on signale pour revue manuelle (intégrité avant tout).

Usage :
    python -m paris_memoire.enrich_entities            # dry-run (n'écrit rien)
    python -m paris_memoire.enrich_entities --apply     # écrit en base
    python -m paris_memoire.enrich_entities --limit 5
"""
from __future__ import annotations

import argparse

import httpx

from . import supabase_client
from .connectors import gleif, sirene
from .normalize.names import best_match


def resolve_entity(entity: dict, client: httpx.Client) -> dict:
    """Retourne les champs à mettre à jour + des notes, sans rien écrire."""
    name = entity.get("legal_name") or entity.get("display_name") or ""
    updates: dict[str, str] = {}
    notes: list[str] = []

    # LEI via GLEIF
    if not entity.get("lei"):
        candidates = gleif.search_lei(name, entity.get("country"), client=client)
        match = best_match(name, candidates, "legal_name")
        if match and match.get("lei"):
            updates["lei"] = match["lei"]
            if not entity.get("country") and match.get("country"):
                updates["country"] = match["country"]
            parent = gleif.direct_parent(match["lei"], client=client)
            if parent and parent.get("legal_name"):
                notes.append(f"parent GLEIF suggéré: {parent['legal_name']} ({parent.get('lei')})")
        else:
            notes.append("LEI non résolu (aucune correspondance nette)")

    # SIREN via SIRENE (France uniquement)
    if not entity.get("siren") and (entity.get("country") in (None, "FR")):
        results = sirene.search_siren(name, client=client)
        match = best_match(name, results, "nom")
        if match and match.get("siren"):
            updates["siren"] = match["siren"]
        else:
            notes.append("SIREN non résolu (aucune correspondance nette)")

    return {"updates": updates, "notes": notes}


def run(apply: bool = False, limit: int | None = None) -> None:
    entities = supabase_client.list_entities()
    if limit:
        entities = entities[:limit]

    print(f"{len(entities)} entités à traiter — mode {'APPLY' if apply else 'DRY-RUN'}\n")
    with httpx.Client(timeout=20) as client:
        for e in entities:
            res = resolve_entity(e, client)
            updates, notes = res["updates"], res["notes"]
            label = e.get("display_name") or e.get("legal_name") or e.get("slug")
            if updates:
                print(f"✔ {label}: {updates}")
                if apply:
                    supabase_client.update_entity(e["id"], updates, client=client)
            else:
                print(f"· {label}: rien à mettre à jour")
            for n in notes:
                print(f"    ↳ {n}")

    if not apply:
        print("\n(dry-run : aucune écriture. Relancer avec --apply pour écrire en base.)")


def main() -> None:
    parser = argparse.ArgumentParser(description="Enrichissement LEI/SIREN des entités.")
    parser.add_argument("--apply", action="store_true", help="écrit en base (sinon dry-run)")
    parser.add_argument("--limit", type=int, default=None, help="limiter le nombre d'entités")
    args = parser.parse_args()
    run(apply=args.apply, limit=args.limit)


if __name__ == "__main__":
    main()
