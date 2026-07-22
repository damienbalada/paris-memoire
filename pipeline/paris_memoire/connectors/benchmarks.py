"""Connecteur Benchmarks tiers — BBFAW (ANI), KnowTheChain & FTI (SUP).

Rend ré-ingérable (et actualisable) le travail de curation qui était saisi à la
main en SQL. Module PUR : parsing + normalisation + matching ; l'accès réseau/DB
se fait via import_benchmarks.py.

Benchmarks pris en charge :
  * bbfaw        — Business Benchmark on Farm Animal Welfare : Tier 1 (meilleur)
                   à Tier 6 (« aucune preuve à l'agenda »). Indicateur ANI_BBFAW_TIER (ordinal).
  * knowthechain — KnowTheChain (travail forcé), score /100. Indicateur SUP_KNOWTHECHAIN.
  * fti          — Fashion Transparency Index, score en %. Indicateur SUP_FTI_SCORE.

Normalisation :
  * BBFAW  : Tier 1 -> 1.0 ... Tier 6 -> 0.10 (échelle linéaire, cohérente avec la curation).
  * scores : score/100, borné [0,1].

On part de la DONNÉE benchmark et on cherche l'entité correspondante (groupe OU
marque) par nom fort ; en cas de doute, on saute (pas d'invention).
"""
from __future__ import annotations

import csv
import re
from dataclasses import dataclass

from ..normalize.names import is_strong_match

NAME_COLS = ("company", "name", "entity", "société", "nom", "brand", "marque")
TIER_COLS = ("tier", "bbfaw_tier", "niveau")
SCORE_COLS = ("score", "value", "note", "points", "percent", "pct")

# Métadonnées par benchmark : (indicateur, source, URL par défaut).
BENCHMARKS = {
    "bbfaw": ("ANI_BBFAW_TIER", "BBFAW", "https://www.bbfaw.com/"),
    "knowthechain": ("SUP_KNOWTHECHAIN", "KNOWTHECHAIN", "https://www.knowthechain.org/"),
    "fti": ("SUP_FTI_SCORE", "FTI", "https://www.fashionrevolution.org/"),
}


@dataclass
class BenchmarkRow:
    company: str
    indicator_code: str
    source_code: str
    value_type: str            # ordinal / numeric
    normalized_value: float
    value_text: str
    source_url: str
    value_numeric: float | None = None


def norm_bbfaw_tier(tier: int) -> float:
    """Tier 1 -> 1.0 ... Tier 6 -> 0.10 (linéaire)."""
    return round((6 - tier) / 5 * 0.9 + 0.10, 4)


def parse_tier(raw: str | None) -> int | None:
    """'Tier 6' / '6' / 'T6' -> 6. None si absent ou hors 1..6."""
    if raw is None:
        return None
    m = re.search(r"\d+", str(raw))
    if not m:
        return None
    t = int(m.group())
    return t if 1 <= t <= 6 else None


def parse_score(raw: str | None) -> float | None:
    """'55' / '55/100' / '80 %' -> float dans [0,100]. None si vide/aberrant."""
    if raw is None:
        return None
    s = str(raw).strip().replace("%", "").replace(",", ".")
    s = re.sub(r"/\s*\d+\s*$", "", s).strip()  # retire un éventuel '/100'
    if not s:
        return None
    try:
        v = float(s)
    except ValueError:
        return None
    return v if 0 <= v <= 100 else None


def norm_score(score: float) -> float:
    return max(0.0, min(score / 100.0, 1.0))


def _pick(row: dict, cols: tuple[str, ...]) -> str | None:
    lower = {k.lower().strip(): v for k, v in row.items()}
    for c in cols:
        if c in lower and lower[c] not in (None, ""):
            return lower[c]
    return None


def _row_bbfaw(name: str, raw: dict, url: str) -> BenchmarkRow | None:
    tier = parse_tier(_pick(raw, TIER_COLS))
    if tier is None:
        return None
    ind, src, default_url = BENCHMARKS["bbfaw"]
    return BenchmarkRow(
        company=name, indicator_code=ind, source_code=src, value_type="ordinal",
        normalized_value=norm_bbfaw_tier(tier), value_text=f"Tier {tier}",
        source_url=url or default_url,
    )


def _row_score(name: str, raw: dict, benchmark: str, url: str, unit: str) -> BenchmarkRow | None:
    score = parse_score(_pick(raw, SCORE_COLS))
    if score is None:
        return None
    ind, src, default_url = BENCHMARKS[benchmark]
    return BenchmarkRow(
        company=name, indicator_code=ind, source_code=src, value_type="numeric",
        normalized_value=round(norm_score(score), 4), value_numeric=score,
        value_text=f"{score:g}{unit}", source_url=url or default_url,
    )


def parse_csv(path: str, benchmark: str) -> list[BenchmarkRow]:
    """Parse un CSV pour le benchmark donné (colonnes tolérantes à la casse)."""
    if benchmark not in BENCHMARKS:
        raise ValueError(f"Benchmark inconnu : {benchmark!r} (attendu: {', '.join(BENCHMARKS)})")
    out: list[BenchmarkRow] = []
    with open(path, newline="", encoding="utf-8-sig") as f:
        for raw in csv.DictReader(f):
            name = _pick(raw, NAME_COLS)
            if not name:
                continue
            name = name.strip()
            url = _pick(raw, ("source_url", "url")) or ""
            if benchmark == "bbfaw":
                row = _row_bbfaw(name, raw, url)
            elif benchmark == "knowthechain":
                row = _row_score(name, raw, "knowthechain", url, "/100")
            else:  # fti
                row = _row_score(name, raw, "fti", url, " %")
            if row is not None:
                out.append(row)
    return out


def match_entity(row: BenchmarkRow, entities: list[dict]) -> dict | None:
    """Cherche l'entité (groupe OU marque) dont le nom correspond nettement."""
    for e in entities:
        for key in ("display_name", "legal_name", "slug"):
            val = e.get(key)
            if val and is_strong_match(row.company, val):
                return e
    return None
