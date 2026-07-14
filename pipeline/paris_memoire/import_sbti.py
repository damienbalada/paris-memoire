"""Import SBTi : statut des objectifs climat (validé / engagé / retiré).

Usage :
    # 1) Télécharger l'export « Companies taking action » (CSV) :
    #    https://sciencebasedtargets.org/companies-taking-action
    # 2) Dry-run :
    python -m paris_memoire.import_sbti --file sbti.csv
    # 3) Écrire (evidence pending, revue humaine ensuite) :
    python -m paris_memoire.import_sbti --file sbti.csv --apply
"""
from __future__ import annotations

import argparse
import datetime as dt

from . import supabase_client
from .connectors import sbti
from .load import EvidenceRow, insert_evidence


def build_rows(entities: list[dict], sbti_rows: list[sbti.SbtiRow], observed_on: str) -> list[EvidenceRow]:
    rows: list[EvidenceRow] = []
    for e in entities:
        if e.get("is_brand"):
            continue  # objectifs climat portés par le groupe, hérités par les marques
        m = sbti.match_company(e, sbti_rows)
        if m is None:
            continue
        rows.append(EvidenceRow(
            entity_slug=e["slug"], indicator_code="ENV_SBTI_VALIDATED", source_code="SBTI",
            nature=m.nature, observed_on=observed_on, value_type="category",
            value_text=m.label, normalized_value=m.normalized_value, confidence=0.85,
            source_url=sbti.SBTI_SOURCE_URL,
            excerpt=f"SBTi : « {m.company} » — {m.label} ({'résultat validé' if m.nature == 'result' else 'engagement non validé'})",
        ))
    return rows


def main() -> None:
    parser = argparse.ArgumentParser(description="Import SBTi (objectifs climat).")
    parser.add_argument("--file", required=True, help="CSV SBTi téléchargé")
    parser.add_argument("--apply", action="store_true", help="écrit en base (sinon dry-run)")
    args = parser.parse_args()

    sbti_rows = sbti.parse_csv(args.file)
    print(f"{len(sbti_rows)} lignes exploitables dans l'export SBTi")

    entities = supabase_client.list_entities()
    rows = build_rows(entities, sbti_rows, observed_on=dt.date.today().isoformat())
    for r in rows:
        print(f"✔ {r.entity_slug}: ENV_SBTI_VALIDATED = {r.normalized_value} [{r.nature}] ({r.value_text})")
    print(f"\n{len(rows)} evidence à insérer (pending)")

    if args.apply:
        stats = insert_evidence(rows)
        print(f"Insérées: {stats['inserted']} · ignorées: {stats['skipped']}")
    else:
        print("(dry-run : rien n'a été écrit. Relancer avec --apply.)")


if __name__ == "__main__":
    main()
