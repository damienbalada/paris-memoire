"""Import CDP : notes climat & eau (evidence pending).

Usage :
    # CSV avec company + cdp_climate et/ou cdp_water (lettre A..D- / F)
    python -m paris_memoire.import_cdp --file cdp.csv            # dry-run
    python -m paris_memoire.import_cdp --file cdp.csv --apply    # écrit (pending)

Comme tout le pipeline : evidence en `pending` (revue humaine avant de compter),
notes CDP consolidées au niveau du GROUPE (les marques héritent), matching conservateur.
"""
from __future__ import annotations

import argparse
import datetime as dt

from . import supabase_client
from .connectors import cdp
from .load import EvidenceRow, insert_evidence

SOURCE_CODE = "CDP"


def build_rows(entities: list[dict], records: list[cdp.CdpRecord], observed_on: str) -> list[EvidenceRow]:
    rows: list[EvidenceRow] = []
    for e in entities:
        if e.get("is_brand"):
            continue  # note CDP consolidée au niveau groupe, héritée par les marques
        m = cdp.match_company(e, records)
        if m is None:
            continue
        for indicator_code, note, label in (
            ("ENV_CDP_CLIMATE", m.climate, "climat"),
            ("WAT_CDP", m.water, "eau"),
        ):
            if note is None:
                continue
            grade, nv = note
            rows.append(EvidenceRow(
                entity_slug=e["slug"], indicator_code=indicator_code, source_code=SOURCE_CODE,
                nature="result", observed_on=observed_on, value_type="ordinal",
                value_text=grade, normalized_value=nv, confidence=0.85,
                source_url=cdp.CDP_SOURCE_URL,
                excerpt=f"Note CDP {label} : {grade} ({m.company}).",
            ))
    return rows


def main() -> None:
    parser = argparse.ArgumentParser(description="Import CDP (note climat).")
    parser.add_argument("--file", required=True, help="CSV CDP")
    parser.add_argument("--apply", action="store_true", help="écrit en base (sinon dry-run)")
    args = parser.parse_args()

    records = cdp.parse_csv(args.file)
    print(f"{len(records)} notes CDP lues")

    entities = supabase_client.list_entities()
    rows = build_rows(entities, records, observed_on=dt.date.today().isoformat())
    for r in rows:
        print(f"✔ {r.entity_slug}: {r.value_text} (norm {r.normalized_value})")
    print(f"\n{len(rows)} evidence à insérer (pending)")

    if args.apply:
        stats = insert_evidence(rows)
        print(f"Insérées: {stats['inserted']} · ignorées: {stats['skipped']}")
    else:
        print("(dry-run : rien n'a été écrit. Relancer avec --apply.)")


if __name__ == "__main__":
    main()
