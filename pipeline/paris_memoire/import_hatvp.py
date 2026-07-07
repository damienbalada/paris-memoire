"""Import HATVP : inscription au répertoire + dépenses de lobbying déclarées.

Usage :
    # 1) Télécharger l'open data AGORA (JSON) depuis https://www.hatvp.fr/agora/opendata/
    # 2) Dry-run (n'écrit rien) :
    python -m paris_memoire.import_hatvp --file agora_repertoire.json
    # 3) Écrire en base (evidence en statut pending, revue humaine ensuite) :
    python -m paris_memoire.import_hatvp --file agora_repertoire.json --apply
"""
from __future__ import annotations

import argparse
import datetime as dt

from . import supabase_client
from .connectors import hatvp
from .load import EvidenceRow, insert_evidence


def build_rows(entities: list[dict], orgs: list[hatvp.HatvpOrg], observed_on: str) -> list[EvidenceRow]:
    rows: list[EvidenceRow] = []
    for e in entities:
        org = hatvp.match_org(e, orgs)
        if org is None:
            continue
        excerpt = f"Inscrit au répertoire HATVP sous « {org.denomination} »"
        rows.append(EvidenceRow(
            entity_slug=e["slug"], indicator_code="GEO_LOBBYING_TRANSP", source_code="HATVP",
            nature="result", observed_on=observed_on, value_type="boolean",
            value_boolean=True, normalized_value=1.0, confidence=0.9,
            source_url=hatvp.HATVP_SOURCE_URL, excerpt=excerpt,
        ))
        if org.spend_mid is not None:
            rows.append(EvidenceRow(
                entity_slug=e["slug"], indicator_code="GEO_LOBBYING_SPEND", source_code="HATVP",
                nature="result", observed_on=observed_on, value_type="numeric",
                value_numeric=org.spend_mid, confidence=0.8,
                source_url=hatvp.HATVP_SOURCE_URL,
                excerpt=f"{excerpt} — dépenses déclarées ~{org.spend_mid:,.0f} € ({org.year or 'exercice n.c.'})",
            ))
    return rows


def main() -> None:
    parser = argparse.ArgumentParser(description="Import HATVP (lobbying).")
    parser.add_argument("--file", required=True, help="JSON open data AGORA téléchargé")
    parser.add_argument("--apply", action="store_true", help="écrit en base (sinon dry-run)")
    args = parser.parse_args()

    orgs = hatvp.load_registry_file(args.file)
    print(f"{len(orgs)} organisations dans le répertoire HATVP")

    entities = supabase_client.list_entities()
    rows = build_rows(entities, orgs, observed_on=dt.date.today().isoformat())
    for r in rows:
        print(f"✔ {r.entity_slug}: {r.indicator_code} = "
              f"{r.value_numeric if r.value_numeric is not None else r.value_boolean}")
    print(f"\n{len(rows)} evidence à insérer (statut pending, revue humaine ensuite)")

    if args.apply:
        stats = insert_evidence(rows)
        print(f"Insérées: {stats['inserted']} · ignorées (doublons/refs): {stats['skipped']}")
    else:
        print("(dry-run : rien n'a été écrit. Relancer avec --apply.)")


if __name__ == "__main__":
    main()
