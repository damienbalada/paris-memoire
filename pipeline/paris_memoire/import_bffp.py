"""Import BFFP : classement pollueurs plastique -> gate PLA_POLLUTER (pending).

Usage :
    # CSV : company + rank (ou band : top3/top10/top50)
    python -m paris_memoire.import_bffp --file bffp.csv            # dry-run
    python -m paris_memoire.import_bffp --file bffp.csv --apply    # écrit (pending)

⚠️ PLA_POLLUTER est un indicateur-GATE écrit comme CONTROVERSE : la valeur écrite
est la SÉVÉRITÉ de la pollution (haute = fort pollueur). Le moteur en dérive le
plafond de la dimension (plafond bas pour les pires pollueurs). Voir
connectors/bffp.py. Tier audited_ngo.

Comme tout le pipeline : evidence en `pending`, matching conservateur. Un audit
peut nommer une marque ou un groupe : on s'attache à l'entité nommée.
"""
from __future__ import annotations

import argparse
import datetime as dt

from . import supabase_client
from .connectors import bffp
from .load import EvidenceRow, insert_evidence


def build_rows(entities: list[dict], records: list[bffp.BffpRecord], observed_on: str) -> list[EvidenceRow]:
    rows: list[EvidenceRow] = []
    for r in records:
        e = bffp.match_entity(r, entities)
        if e is None:
            continue
        rows.append(EvidenceRow(
            entity_slug=e["slug"], indicator_code="PLA_POLLUTER", source_code="BFFP",
            nature="controversy", observed_on=observed_on, value_type="category",
            value_text=r.label, normalized_value=r.severity, confidence=0.82,
            source_url=bffp.BFFP_SOURCE_URL,
            excerpt=f"Classé {r.label} des pollueurs plastique (audits BFFP) — "
                    f"plafonne la note plastique (sévérité {r.severity:g}).",
        ))
    return rows


def main() -> None:
    parser = argparse.ArgumentParser(description="Import BFFP (pollueurs plastique, gate PLA).")
    parser.add_argument("--file", required=True, help="CSV BFFP")
    parser.add_argument("--apply", action="store_true", help="écrit en base (sinon dry-run)")
    args = parser.parse_args()

    records = bffp.parse_csv(args.file)
    print(f"{len(records)} lignes BFFP lues")

    entities = supabase_client.list_entities()
    rows = build_rows(entities, records, observed_on=dt.date.today().isoformat())
    for r in rows:
        print(f"✔ {r.entity_slug}: PLA_POLLUTER = {r.value_text} (sévérité {r.normalized_value})")
    print(f"\n{len(rows)} evidence à insérer (pending) · "
          f"{len(records) - len(rows)} ligne(s) sans entité connue")

    if args.apply:
        stats = insert_evidence(rows)
        print(f"Insérées: {stats['inserted']} · ignorées: {stats['skipped']}")
    else:
        print("(dry-run : rien n'a été écrit. Relancer avec --apply.)")


if __name__ == "__main__":
    main()
