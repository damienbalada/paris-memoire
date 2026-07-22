"""Import Gouvernance : mixité + indépendance du conseil (evidence pending).

Usage :
    # CSV avec au moins : company + women_share (+ independent_share)
    python -m paris_memoire.import_governance --file gov.csv            # dry-run
    python -m paris_memoire.import_governance --file gov.csv --apply    # écrit (pending)

Comme tout le pipeline : evidence en `pending` (revue humaine avant de compter),
gouvernance portée par le GROUPE (les marques héritent), matching conservateur.
"""
from __future__ import annotations

import argparse
import datetime as dt

from . import supabase_client
from .connectors import governance as gov
from .load import EvidenceRow, insert_evidence

SOURCE_CODE = "CSRD_ESRS"


def build_rows(entities: list[dict], records: list[gov.GovRecord], observed_on: str,
               source_url: str = gov.GOV_SOURCE_URL) -> list[EvidenceRow]:
    rows: list[EvidenceRow] = []
    for e in entities:
        if e.get("is_brand"):
            continue  # gouvernance au niveau groupe, héritée par les marques
        m = gov.match_company(e, records)
        if m is None:
            continue
        if m.women_share is not None:
            pct = round(m.women_share * 100)
            rows.append(EvidenceRow(
                entity_slug=e["slug"], indicator_code="GOV_BOARD_GENDER", source_code=SOURCE_CODE,
                nature="result", observed_on=observed_on, value_type="numeric",
                value_numeric=float(pct), value_text=f"{pct} %",
                normalized_value=round(gov.norm_gender(m.women_share), 4), confidence=0.85,
                source_url=source_url,
                excerpt=f"Conseil d'administration : {pct} % de femmes ({m.company}).",
            ))
        if m.independent_share is not None:
            pct = round(m.independent_share * 100)
            rows.append(EvidenceRow(
                entity_slug=e["slug"], indicator_code="GOV_BOARD_INDEP", source_code=SOURCE_CODE,
                nature="result", observed_on=observed_on, value_type="numeric",
                value_numeric=float(pct), value_text=f"{pct} %",
                normalized_value=round(gov.norm_independence(m.independent_share), 4), confidence=0.85,
                source_url=source_url,
                excerpt=f"Conseil d'administration : {pct} % d'administrateurs indépendants ({m.company}).",
            ))
    return rows


def main() -> None:
    parser = argparse.ArgumentParser(description="Import gouvernance (conseil).")
    parser.add_argument("--file", required=True, help="CSV gouvernance")
    parser.add_argument("--apply", action="store_true", help="écrit en base (sinon dry-run)")
    args = parser.parse_args()

    records = gov.parse_csv(args.file)
    print(f"{len(records)} enregistrements de gouvernance lus")

    entities = supabase_client.list_entities()
    rows = build_rows(entities, records, observed_on=dt.date.today().isoformat())
    for r in rows:
        print(f"✔ {r.entity_slug}: {r.indicator_code} = {r.value_text} (norm {r.normalized_value})")
    print(f"\n{len(rows)} evidence à insérer (pending)")

    if args.apply:
        stats = insert_evidence(rows)
        print(f"Insérées: {stats['inserted']} · ignorées: {stats['skipped']}")
    else:
        print("(dry-run : rien n'a été écrit. Relancer avec --apply.)")


if __name__ == "__main__":
    main()
