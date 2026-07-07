"""Import liste Yale (Russie) : position de chaque groupe.

Usage :
    # 1) Télécharger le CSV depuis https://www.yalerussianbusinessretreat.org/
    # 2) Dry-run :
    python -m paris_memoire.import_yale --file yale.csv
    # 3) Écrire (evidence pending, revue humaine ensuite) :
    python -m paris_memoire.import_yale --file yale.csv --apply
"""
from __future__ import annotations

import argparse
import datetime as dt

from . import supabase_client
from .connectors import yale_russia
from .load import EvidenceRow, insert_evidence


def build_rows(entities: list[dict], yale_rows: list[yale_russia.YaleRow], observed_on: str) -> list[EvidenceRow]:
    rows: list[EvidenceRow] = []
    for e in entities:
        if e.get("is_brand"):
            continue  # position Russie portée par le groupe, héritée par les marques
        m = yale_russia.match_company(e, yale_rows)
        if m is None:
            continue
        rows.append(EvidenceRow(
            entity_slug=e["slug"], indicator_code="GEO_RUSSIA_EXIT", source_code="YALE_RUSSIA",
            nature="result", observed_on=observed_on, value_type="category",
            value_text=m.label, normalized_value=m.value, confidence=0.85,
            source_url=yale_russia.YALE_SOURCE_URL,
            excerpt=f"Liste Yale CELI : « {m.company} » — {m.label}",
        ))
    return rows


def main() -> None:
    parser = argparse.ArgumentParser(description="Import liste Yale (Russie).")
    parser.add_argument("--file", required=True, help="CSV Yale téléchargé")
    parser.add_argument("--apply", action="store_true", help="écrit en base (sinon dry-run)")
    args = parser.parse_args()

    yale_rows = yale_russia.parse_csv(args.file)
    print(f"{len(yale_rows)} lignes exploitables dans le CSV Yale")

    entities = supabase_client.list_entities()
    rows = build_rows(entities, yale_rows, observed_on=dt.date.today().isoformat())
    for r in rows:
        print(f"✔ {r.entity_slug}: GEO_RUSSIA_EXIT = {r.normalized_value} ({r.value_text})")
    print(f"\n{len(rows)} evidence à insérer (statut pending, revue humaine ensuite)")

    if args.apply:
        stats = insert_evidence(rows)
        print(f"Insérées: {stats['inserted']} · ignorées (doublons/refs): {stats['skipped']}")
    else:
        print("(dry-run : rien n'a été écrit. Relancer avec --apply.)")


if __name__ == "__main__":
    main()
