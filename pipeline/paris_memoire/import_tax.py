"""Import Fiscalité : CbCR + taux effectif + paradis fiscaux (evidence pending).

Usage :
    # CSV avec au moins : company + une des colonnes cbcr / effective_tax_rate / haven_entities
    python -m paris_memoire.import_tax --file tax.csv            # dry-run
    python -m paris_memoire.import_tax --file tax.csv --apply    # écrit (pending)

Comme tout le pipeline : evidence en `pending` (revue humaine avant de compter),
fiscalité portée par le GROUPE (comptes consolidés ; les marques héritent),
matching de noms conservateur.

Les quantitatifs (taux effectif, paradis fiscaux) sont insérés en valeur BRUTE,
sans normalized_value : le moteur calcule le percentile intra-secteur et applique
la direction (higher_better / lower_better). Le CbCR (binaire) est normalisé ici.
"""
from __future__ import annotations

import argparse
import datetime as dt

from . import supabase_client
from .connectors import tax
from .load import EvidenceRow, insert_evidence

SOURCE_URL = "https://www.oecd.org/tax/beps/country-by-country-reporting-appendix-iv.htm"


def build_rows(entities: list[dict], records: list[tax.TaxRecord], observed_on: str) -> list[EvidenceRow]:
    rows: list[EvidenceRow] = []
    for e in entities:
        if e.get("is_brand"):
            continue  # fiscalité consolidée au niveau groupe, héritée par les marques
        m = tax.match_company(e, records)
        if m is None:
            continue

        if m.cbcr_published is not None:
            rows.append(EvidenceRow(
                entity_slug=e["slug"], indicator_code="TAX_CBCR_PUBLISHED", source_code=tax.CBCR_SOURCE,
                nature="result", observed_on=observed_on, value_type="boolean",
                value_boolean=m.cbcr_published,
                normalized_value=1.0 if m.cbcr_published else 0.0, confidence=0.90,
                source_url=SOURCE_URL,
                excerpt=("Reporting pays-par-pays public"
                         if m.cbcr_published else "Pas de reporting pays-par-pays public")
                        + f" ({m.company}).",
            ))

        if m.effective_rate is not None:
            rows.append(EvidenceRow(
                entity_slug=e["slug"], indicator_code="TAX_EFFECTIVE_RATE", source_code=tax.ETR_SOURCE,
                nature="result", observed_on=observed_on, value_type="numeric",
                value_numeric=m.effective_rate, value_text=f"{m.effective_rate:g} %",
                normalized_value=None, confidence=0.85,  # percentile intra-secteur calculé par le moteur
                source_url=None,
                excerpt=f"Taux effectif d'imposition : {m.effective_rate:g} % ({m.company}).",
            ))

        if m.haven_entities is not None:
            rows.append(EvidenceRow(
                entity_slug=e["slug"], indicator_code="TAX_HAVEN_PRESENCE", source_code=tax.HAVEN_SOURCE,
                nature="result", observed_on=observed_on, value_type="numeric",
                value_numeric=float(m.haven_entities), value_text=str(m.haven_entities),
                normalized_value=None, confidence=0.75,  # percentile inversé calculé par le moteur
                source_url="https://taxjustice.net",
                excerpt=f"{m.haven_entities} entité(s) en juridiction à faible imposition ({m.company}).",
            ))
    return rows


def main() -> None:
    parser = argparse.ArgumentParser(description="Import fiscalité (CbCR / taux effectif / paradis fiscaux).")
    parser.add_argument("--file", required=True, help="CSV fiscalité")
    parser.add_argument("--apply", action="store_true", help="écrit en base (sinon dry-run)")
    args = parser.parse_args()

    records = tax.parse_csv(args.file)
    print(f"{len(records)} enregistrements de fiscalité lus")

    entities = supabase_client.list_entities()
    rows = build_rows(entities, records, observed_on=dt.date.today().isoformat())
    for r in rows:
        print(f"✔ {r.entity_slug}: {r.indicator_code} = {r.value_text or r.value_boolean} "
              f"(norm {r.normalized_value})")
    print(f"\n{len(rows)} evidence à insérer (pending)")

    if args.apply:
        stats = insert_evidence(rows)
        print(f"Insérées: {stats['inserted']} · ignorées: {stats['skipped']}")
    else:
        print("(dry-run : rien n'a été écrit. Relancer avec --apply.)")


if __name__ == "__main__":
    main()
