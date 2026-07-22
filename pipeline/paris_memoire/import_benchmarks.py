"""Import Benchmarks tiers : BBFAW / KnowTheChain / FTI (evidence pending).

Usage :
    python -m paris_memoire.import_benchmarks --benchmark bbfaw       --file bbfaw.csv
    python -m paris_memoire.import_benchmarks --benchmark knowthechain --file ktc.csv --apply
    python -m paris_memoire.import_benchmarks --benchmark fti          --file fti.csv --apply

CSV attendu : une colonne nom (company/name/brand…) + la valeur du benchmark :
  * bbfaw        -> colonne 'tier' ('Tier 6', '6', …)
  * knowthechain -> colonne 'score' (/100)
  * fti          -> colonne 'score' (en %)
Colonne 'source_url' facultative (URL précise du rapport) sinon URL par défaut.

Comme tout le pipeline : evidence en `pending` (revue humaine avant de compter),
matching de noms conservateur. Contrairement à gouvernance/fiscalité (niveau
groupe), un benchmark peut noter une MARQUE (ex. FTI note Gucci) : on attache
l'evidence à l'entité nommée, groupe ou marque.
"""
from __future__ import annotations

import argparse
import datetime as dt

from . import supabase_client
from .connectors import benchmarks as bm
from .load import EvidenceRow, insert_evidence


def build_rows(entities: list[dict], rows: list[bm.BenchmarkRow], observed_on: str) -> list[EvidenceRow]:
    out: list[EvidenceRow] = []
    for r in rows:
        e = bm.match_entity(r, entities)
        if e is None:
            continue
        out.append(EvidenceRow(
            entity_slug=e["slug"], indicator_code=r.indicator_code, source_code=r.source_code,
            nature="result", observed_on=observed_on, value_type=r.value_type,
            value_numeric=r.value_numeric, value_text=r.value_text,
            normalized_value=r.normalized_value, confidence=0.85,
            source_url=r.source_url,
            excerpt=f"{r.company} — {r.value_text} ({r.source_code}).",
        ))
    return out


def main() -> None:
    parser = argparse.ArgumentParser(description="Import benchmarks (BBFAW / KnowTheChain / FTI).")
    parser.add_argument("--benchmark", required=True, choices=sorted(bm.BENCHMARKS),
                        help="benchmark source")
    parser.add_argument("--file", required=True, help="CSV du benchmark")
    parser.add_argument("--apply", action="store_true", help="écrit en base (sinon dry-run)")
    args = parser.parse_args()

    rows = bm.parse_csv(args.file, args.benchmark)
    print(f"{len(rows)} lignes {args.benchmark} lues")

    entities = supabase_client.list_entities()
    ev = build_rows(entities, rows, observed_on=dt.date.today().isoformat())
    for r in ev:
        print(f"✔ {r.entity_slug}: {r.indicator_code} = {r.value_text} (norm {r.normalized_value})")
    print(f"\n{len(ev)} evidence à insérer (pending) · "
          f"{len(rows) - len(ev)} ligne(s) sans entité connue")

    if args.apply:
        stats = insert_evidence(ev)
        print(f"Insérées: {stats['inserted']} · ignorées: {stats['skipped']}")
    else:
        print("(dry-run : rien n'a été écrit. Relancer avec --apply.)")


if __name__ == "__main__":
    main()
