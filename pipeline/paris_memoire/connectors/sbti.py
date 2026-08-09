"""Connecteur SBTi — Science Based Targets initiative.

Données : export « Companies taking action » téléchargeable sur
https://sciencebasedtargets.org/companies-taking-action (XLSX ou CSV).

Produit ENV_SBTI_VALIDATED. Le cœur anti-greenwashing du pilier ENV :
  * « Targets Set » + classification 1.5°C  -> normalized 1.0, nature=result
  * « Targets Set » (autre classification)  -> normalized 0.6, nature=result
  * « Committed » (simple engagement)       -> normalized 1.0, nature=commitment
      (le moteur applique alors le multiplicateur promesse x0.4 + plafond 0.5)
  * « Removed » (engagement retiré)         -> normalized 0.0, nature=result

Matching : nom en correspondance nette uniquement (conservateur).
"""
from __future__ import annotations

import csv
from dataclasses import dataclass

from ..normalize.names import is_strong_match

SBTI_SOURCE_URL = "https://sciencebasedtargets.org/companies-taking-action"

# En-tetes normalises (underscores et tirets ramenes a des espaces) : l'export
# SBTi a change de convention au fil du temps (Company Name, puis
# Near term - Target Status, puis aujourd'hui company_name, near_term_status).
# On tolere les trois formes plutot que de casser a chaque refonte de la source.
NAME_COLS = ("company name", "company", "name")
STATUS_COLS = ("near term status", "near term target status", "target status", "status")
CLASSIF_COLS = ("near term target classification", "target classification", "classification")


def _norm_key(k: str) -> str:
    """Cle d'en-tete comparable : minuscule, _/- -> espace, espaces compactes."""
    k = k.lower().strip().replace("_", " ").replace("-", " ")
    return " ".join(k.split())


@dataclass
class SbtiRow:
    company: str
    normalized_value: float
    nature: str
    label: str


def _interpret(status: str, classification: str) -> tuple[float, str] | None:
    """(normalized_value, nature) selon statut + classification. None si inconnu."""
    s = status.strip().lower()
    c = classification.strip().lower()
    if "targets set" in s or s == "set":
        return (1.0, "result") if "1.5" in c else (0.6, "result")
    if "committed" in s:
        return (1.0, "commitment")
    if "removed" in s:
        return (0.0, "result")
    return None


def parse_csv(path: str) -> list[SbtiRow]:
    """Parse l'export SBTi (CSV, colonnes tolerantes a la casse)."""
    rows: list[SbtiRow] = []
    with open(path, encoding="utf-8-sig", newline="") as f:
        reader = csv.DictReader(f)
        fields = {_norm_key(k): k for k in (reader.fieldnames or [])}
        name_col = next((fields[k] for k in NAME_COLS if k in fields), None)
        status_col = next((fields[k] for k in STATUS_COLS if k in fields), None)
        classif_col = next((fields[k] for k in CLASSIF_COLS if k in fields), None)
        if not name_col or not status_col:
            raise ValueError(
                f"Colonnes introuvables (vues: {reader.fieldnames}). "
                "Attendu: Company Name + Target Status. "
                "Si le fichier est en .xlsx, l'exporter/convertir en CSV.")
        for r in reader:
            company = (r.get(name_col) or "").strip()
            if not company:
                continue
            interp = _interpret(r.get(status_col) or "", (r.get(classif_col) or "") if classif_col else "")
            if interp is None:
                continue
            value, nature = interp
            rows.append(SbtiRow(company=company, normalized_value=value, nature=nature,
                                label=(r.get(status_col) or "").strip()))
    return rows


def match_company(entity: dict, rows: list[SbtiRow]) -> SbtiRow | None:
    """Nom en correspondance nette uniquement (conservateur)."""
    name = entity.get("legal_name") or entity.get("display_name") or ""
    display = entity.get("display_name") or ""
    for row in rows:
        if is_strong_match(name, row.company) or (display and is_strong_match(display, row.company)):
            return row
    return None
