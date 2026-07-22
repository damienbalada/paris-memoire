"""Import Investissements & Finance éthique (pilier INV) — evidence pending.

Usage :
    # CSV : company + au moins une de responsible_policy / sustainable_finance /
    #       fossil_financing / controversial_holdings
    python -m paris_memoire.import_investments --file inv.csv            # dry-run
    python -m paris_memoire.import_investments --file inv.csv --apply    # écrit (pending)

Comme tout le pipeline : evidence en `pending`, portée par le GROUPE (les marques
héritent), matching conservateur. Les quantitatifs (fossile, participations) sont
insérés en VALEUR BRUTE : le moteur calcule le percentile intra-secteur (lower_better).
"""
from __future__ import annotations

import argparse
import datetime as dt

from . import supabase_client
from .connectors import investments as inv
from .load import EvidenceRow, insert_evidence


def build_rows(entities: list[dict], records: list[inv.InvRecord], observed_on: str) -> list[EvidenceRow]:
    rows: list[EvidenceRow] = []
    for e in entities:
        if e.get("is_brand"):
            continue  # finance consolidée au niveau groupe, héritée par les marques
        m = inv.match_company(e, records)
        if m is None:
            continue

        for indicator_code, status, source, url in (
            ("INV_RESPONSIBLE_POLICY", m.responsible_policy, inv.UNPRI_SOURCE, inv.UNPRI_URL),
            ("INV_SUSTAINABLE_FINANCE", m.sustainable_finance, inv.UNPRI_SOURCE, inv.UNPRI_URL),
        ):
            if status is None:
                continue
            label, nv, nature = status
            rows.append(EvidenceRow(
                entity_slug=e["slug"], indicator_code=indicator_code, source_code=source,
                nature=nature, observed_on=observed_on, value_type="category",
                value_text=label, normalized_value=nv, confidence=0.80, source_url=url,
                excerpt=f"{m.company} — {label}.",
            ))

        if m.fossil_financing is not None:
            rows.append(EvidenceRow(
                entity_slug=e["slug"], indicator_code="INV_FOSSIL_FINANCING", source_code=inv.RECLAIM_SOURCE,
                nature="result", observed_on=observed_on, value_type="numeric",
                value_numeric=m.fossil_financing, value_text=f"{m.fossil_financing:g}",
                normalized_value=None, confidence=0.80, source_url=inv.RECLAIM_URL,
                excerpt=f"Financement des énergies fossiles : {m.fossil_financing:g} ({m.company}).",
            ))

        if m.controversial_holdings is not None:
            rows.append(EvidenceRow(
                entity_slug=e["slug"], indicator_code="INV_CONTROVERSIAL_HOLDINGS", source_code=inv.RECLAIM_SOURCE,
                nature="result", observed_on=observed_on, value_type="numeric",
                value_numeric=float(m.controversial_holdings), value_text=str(m.controversial_holdings),
                normalized_value=None, confidence=0.75, source_url=inv.RECLAIM_URL,
                excerpt=f"{m.controversial_holdings} participation(s) dans des secteurs controversés ({m.company}).",
            ))
    return rows


def main() -> None:
    parser = argparse.ArgumentParser(description="Import investissements & finance éthique (INV).")
    parser.add_argument("--file", required=True, help="CSV finance")
    parser.add_argument("--apply", action="store_true", help="écrit en base (sinon dry-run)")
    args = parser.parse_args()

    records = inv.parse_csv(args.file)
    print(f"{len(records)} enregistrements finance lus")

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
