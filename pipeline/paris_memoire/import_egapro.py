"""Import Égapro : index d'égalité professionnelle F/H par SIREN.

Prérequis : les SIREN doivent être renseignés (via enrich_entities).

Usage :
    python -m paris_memoire.import_egapro            # dry-run
    python -m paris_memoire.import_egapro --apply     # écrit (pending)
"""
from __future__ import annotations

import argparse

from . import supabase_client
from .connectors import egapro
from .load import EvidenceRow, insert_evidence


def build_rows(entities: list[dict], by_siren: dict[str, egapro.EgaproRecord]) -> list[EvidenceRow]:
    rows: list[EvidenceRow] = []
    for e in entities:
        siren = e.get("siren")
        if not siren:
            continue
        rec = by_siren.get(str(siren))
        if rec is None:
            continue
        observed_on = f"{rec.year}-03-01" if rec.year else "1970-01-01"  # publication annuelle ~1er mars
        rows.append(EvidenceRow(
            entity_slug=e["slug"], indicator_code="LAB_EGAPRO_INDEX", source_code="EGAPRO",
            nature="result", observed_on=observed_on, value_type="numeric",
            value_numeric=rec.note, normalized_value=max(0.0, min(1.0, rec.note / 100.0)),
            confidence=0.95, source_url=egapro.EGAPRO_SOURCE_URL,
            excerpt=f"Index Égapro {rec.year} : {rec.note:.0f}/100 ({rec.raison_sociale or siren})",
        ))
    return rows


def main() -> None:
    parser = argparse.ArgumentParser(description="Import Égapro (index égalité F/H).")
    parser.add_argument("--apply", action="store_true", help="écrit en base (sinon dry-run)")
    args = parser.parse_args()

    entities = supabase_client.list_entities()
    sirens = sorted({str(e["siren"]) for e in entities if e.get("siren")})
    if not sirens:
        raise SystemExit("Aucun SIREN renseigné — lancer d'abord enrich_entities.")
    print(f"{len(sirens)} SIREN à interroger")

    records = egapro.fetch_for_sirens(sirens)
    by_siren = egapro.latest_by_siren(records)
    print(f"{len(by_siren)} index Égapro trouvés")

    rows = build_rows(entities, by_siren)
    for r in rows:
        print(f"✔ {r.entity_slug}: LAB_EGAPRO_INDEX = {r.value_numeric}/100")
    print(f"\n{len(rows)} evidence à insérer (pending)")

    if args.apply:
        stats = insert_evidence(rows)
        print(f"Insérées: {stats['inserted']} · ignorées: {stats['skipped']}")
    else:
        print("(dry-run : rien n'a été écrit. Relancer avec --apply.)")


if __name__ == "__main__":
    main()
