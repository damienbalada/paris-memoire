"""Connecteur CDP — notes climat & eau (Carbon Disclosure Project).

Rend ré-ingérable la curation manuelle CDP des seeds ENV/WAT. Module PUR :
parsing + normalisation + matching ; l'accès réseau/DB via import_cdp.py.

Produit ENV_CDP_CLIMATE (climat) et/ou WAT_CDP (sécurité de l'eau), tous deux
ordinaux. La note CDP est une lettre A (leadership) à D- (disclosure), plus F
(« n'a pas répondu »). On pose un barème CANONIQUE et régulier sur [0,1] :
A=1.00 … D-=0.13, F=0.00 — échelle documentée et stable (ce connecteur fait foi).

CDP répond au niveau de l'entité déclarante (le groupe) : evidence portée par le
GROUPE, héritée par les marques. Matching de noms conservateur.
"""
from __future__ import annotations

import csv
from dataclasses import dataclass

from ..normalize.names import is_strong_match

CDP_SOURCE_URL = "https://www.cdp.net/"

NAME_COLS = ("company", "name", "entity", "société", "nom")
CLIMATE_COLS = ("cdp_climate", "cdp", "grade", "score", "note", "climate", "climat")
WATER_COLS = ("cdp_water", "water", "eau", "water_security")

# Barème canonique lettre -> [0,1] (8 bandes A..D- + F).
GRADE_MAP = {
    "A": 1.00, "A-": 0.88,
    "B": 0.75, "B-": 0.63,
    "C": 0.50, "C-": 0.38,
    "D": 0.25, "D-": 0.13,
    "F": 0.00,
}


@dataclass
class CdpRecord:
    company: str
    climate: tuple[str, float] | None = None   # (grade, normalized) climat
    water: tuple[str, float] | None = None      # (grade, normalized) eau


def parse_grade(raw: str | None) -> tuple[str, float] | None:
    """'A-' / 'a −' / 'B' -> (grade, normalized). None si absent ou hors barème."""
    if raw is None:
        return None
    s = str(raw).strip().upper().replace("−", "-").replace(" ", "")
    if not s:
        return None
    if s not in GRADE_MAP:
        return None
    return s, GRADE_MAP[s]


def _pick(row: dict, cols: tuple[str, ...]) -> str | None:
    lower = {k.lower().strip(): v for k, v in row.items()}
    for c in cols:
        if c in lower and lower[c] not in (None, ""):
            return lower[c]
    return None


def parse_csv(path: str) -> list[CdpRecord]:
    out: list[CdpRecord] = []
    with open(path, newline="", encoding="utf-8-sig") as f:
        for row in csv.DictReader(f):
            name = _pick(row, NAME_COLS)
            if not name:
                continue
            climate = parse_grade(_pick(row, CLIMATE_COLS))
            water = parse_grade(_pick(row, WATER_COLS))
            if climate is None and water is None:
                continue  # ni climat ni eau exploitables
            out.append(CdpRecord(company=name.strip(), climate=climate, water=water))
    return out


def match_company(entity: dict, records: list[CdpRecord]) -> CdpRecord | None:
    """1er enregistrement dont le nom correspond nettement, sinon None."""
    q = entity.get("display_name") or entity.get("legal_name") or entity.get("slug") or ""
    for r in records:
        if is_strong_match(q, r.company):
            return r
    return None
