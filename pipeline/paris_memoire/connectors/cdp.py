"""Connecteur CDP — note climat (Carbon Disclosure Project).

Rend ré-ingérable la curation manuelle CDP des seeds ENV (26-31). Module PUR :
parsing + normalisation + matching ; l'accès réseau/DB via import_cdp.py.

Produit ENV_CDP_CLIMATE (ordinal). La note CDP est une lettre A (leadership) à
D- (disclosure), plus F (« n'a pas répondu »). On pose un barème CANONIQUE et
régulier sur [0,1] : A=1.00 … D-=0.13, F=0.00. C'est une échelle documentée et
stable (les anciens seeds divergeaient légèrement — ce connecteur fait foi).

CDP répond au niveau de l'entité déclarante (le groupe) : evidence portée par le
GROUPE, héritée par les marques. Matching de noms conservateur.
"""
from __future__ import annotations

import csv
from dataclasses import dataclass

from ..normalize.names import is_strong_match

CDP_SOURCE_URL = "https://www.cdp.net/"

NAME_COLS = ("company", "name", "entity", "société", "nom")
GRADE_COLS = ("cdp_climate", "cdp", "grade", "score", "note", "climate")

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
    grade: str            # lettre normalisée (ex. 'A-')
    normalized_value: float


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
            g = parse_grade(_pick(row, GRADE_COLS))
            if g is None:
                continue
            grade, nv = g
            out.append(CdpRecord(company=name.strip(), grade=grade, normalized_value=nv))
    return out


def match_company(entity: dict, records: list[CdpRecord]) -> CdpRecord | None:
    """1er enregistrement dont le nom correspond nettement, sinon None."""
    q = entity.get("display_name") or entity.get("legal_name") or entity.get("slug") or ""
    for r in records:
        if is_strong_match(q, r.company):
            return r
    return None
