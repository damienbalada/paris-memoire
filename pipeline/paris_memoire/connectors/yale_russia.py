"""Connecteur liste Yale CELI — positions des entreprises face à la Russie.

La liste Yale (Chief Executive Leadership Institute) est publiée sous forme de
page / tableur sans API stable : télécharger le CSV manuellement, puis lancer
l'import. Colonnes attendues (tolérant à la casse) : Name / Company, et
Grade (A..F) ou Action / Status (texte).

Barème (aligné sur la méthodo de GEO_RUSSIA_EXIT) :
  A withdrawal   -> 1.0   retrait total
  B suspension   -> 0.7   suspension
  C scaling back -> 0.4   réduction
  D buying time  -> 0.2   attentisme
  F digging in   -> 0.0   maintien
"""
from __future__ import annotations

import csv
from dataclasses import dataclass

from ..normalize.names import is_strong_match

YALE_SOURCE_URL = "https://www.yalerussianbusinessretreat.org/"

GRADE_TO_VALUE = {"A": 1.0, "B": 0.7, "C": 0.4, "D": 0.2, "F": 0.0}

STATUS_TO_VALUE = {
    "withdrawal": 1.0, "withdraw": 1.0, "clean break": 1.0, "exit": 1.0,
    "suspension": 0.7, "suspend": 0.7,
    "scaling back": 0.4, "reduction": 0.4,
    "buying time": 0.2, "holding off": 0.2,
    "digging in": 0.0, "remain": 0.0, "staying": 0.0,
}


@dataclass
class YaleRow:
    company: str
    value: float          # [0,1] selon barème
    label: str            # grade ou statut d'origine (traçabilité)


def _value_from(grade: str | None, status: str | None) -> tuple[float, str] | None:
    if grade:
        g = grade.strip().upper()[:1]
        if g in GRADE_TO_VALUE:
            return GRADE_TO_VALUE[g], g
    if status:
        s = status.strip().lower()
        for key, val in STATUS_TO_VALUE.items():
            if key in s:
                return val, status.strip()
    return None


def parse_csv(path: str) -> list[YaleRow]:
    """Parse le CSV Yale (tolérant sur les noms de colonnes)."""
    rows: list[YaleRow] = []
    with open(path, encoding="utf-8-sig", newline="") as f:
        reader = csv.DictReader(f)
        fields = {k.lower().strip(): k for k in (reader.fieldnames or [])}
        name_col = next((fields[k] for k in ("name", "company", "company name", "entreprise") if k in fields), None)
        grade_col = next((fields[k] for k in ("grade", "note") if k in fields), None)
        status_col = next((fields[k] for k in ("action", "status", "statut") if k in fields), None)
        if not name_col or not (grade_col or status_col):
            raise ValueError(
                f"Colonnes introuvables dans le CSV (colonnes vues: {reader.fieldnames}). "
                "Attendu: Name/Company + Grade ou Action/Status.")
        for r in reader:
            company = (r.get(name_col) or "").strip()
            if not company:
                continue
            gv = _value_from(r.get(grade_col) if grade_col else None,
                             r.get(status_col) if status_col else None)
            if gv is None:
                continue
            value, label = gv
            rows.append(YaleRow(company=company, value=value, label=label))
    return rows


def match_company(entity: dict, rows: list[YaleRow]) -> YaleRow | None:
    """Nom en correspondance nette uniquement (conservateur)."""
    name = entity.get("legal_name") or entity.get("display_name") or ""
    display = entity.get("display_name") or ""
    for row in rows:
        if is_strong_match(name, row.company) or (display and is_strong_match(display, row.company)):
            return row
    return None
