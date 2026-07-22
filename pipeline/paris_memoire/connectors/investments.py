"""Connecteur Investissements & Finance éthique (pilier INV).

Rend ré-ingérable la curation manuelle du pilier finance. Module PUR : parsing +
normalisation + matching ; l'accès réseau/DB via import_investments.py.

Produit (selon les colonnes présentes) :
  * INV_RESPONSIBLE_POLICY   — politique d'investissement responsable (statut).
  * INV_SUSTAINABLE_FINANCE  — finance durable / green bonds (statut).
  * INV_FOSSIL_FINANCING     — financement des énergies fossiles (quantitatif).
  * INV_CONTROVERSIAL_HOLDINGS — participations dans des secteurs controversés (count).

Normalisation :
  * statuts   : absent -> 0.0, politique/ponctuel -> 0.5, signataire/cadre -> 1.0.
  * quantitatifs (fossile, participations) : VALEUR BRUTE, sans normalized — le
    moteur calcule le percentile intra-secteur et applique lower_better (moins =
    mieux). Normaliser à la main fausserait la comparaison sectorielle.

INV concerne surtout banque/assurance : evidence portée par le GROUPE. Matching
de noms conservateur.
"""
from __future__ import annotations

import csv
import re
from dataclasses import dataclass

from ..normalize.names import is_strong_match

UNPRI_SOURCE = "UN_PRI"
RECLAIM_SOURCE = "RECLAIM_FINANCE"
UNPRI_URL = "https://www.unpri.org"
RECLAIM_URL = "https://reclaimfinance.org"

NAME_COLS = ("company", "name", "entity", "société", "nom")
POLICY_COLS = ("responsible_policy", "policy", "politique", "pri")
FINANCE_COLS = ("sustainable_finance", "green_bonds", "finance_durable", "sustainable")
FOSSIL_COLS = ("fossil_financing", "fossil", "financement_fossile", "banking_on_climate")
HOLDINGS_COLS = ("controversial_holdings", "holdings", "participations_controversees")

# Statut -> (libellé, normalized, nature) pour les indicateurs catégoriels.
POLICY_STATUS = {
    "signatory": ("signataire UN PRI", 1.0, "result"),
    "signataire": ("signataire UN PRI", 1.0, "result"),
    "pri": ("signataire UN PRI", 1.0, "result"),
    "policy": ("politique déclarée", 0.5, "policy"),
    "politique": ("politique déclarée", 0.5, "policy"),
    "none": ("absente", 0.0, "result"),
    "absente": ("absente", 0.0, "result"),
    "aucune": ("absente", 0.0, "result"),
    "no": ("absente", 0.0, "result"),
}
FINANCE_STATUS = {
    "framework": ("cadre structuré", 1.0, "result"),
    "cadre": ("cadre structuré", 1.0, "result"),
    "structured": ("cadre structuré", 1.0, "result"),
    "occasional": ("émissions ponctuelles", 0.5, "result"),
    "ponctuel": ("émissions ponctuelles", 0.5, "result"),
    "ponctuelle": ("émissions ponctuelles", 0.5, "result"),
    "none": ("aucune", 0.0, "result"),
    "aucun": ("aucune", 0.0, "result"),
    "aucune": ("aucune", 0.0, "result"),
    "no": ("aucune", 0.0, "result"),
}


@dataclass
class InvRecord:
    company: str
    responsible_policy: tuple[str, float, str] | None = None
    sustainable_finance: tuple[str, float, str] | None = None
    fossil_financing: float | None = None       # montant brut (ex. Md$)
    controversial_holdings: int | None = None    # nombre brut


def parse_status(raw: str | None, mapping: dict) -> tuple[str, float, str] | None:
    if raw is None:
        return None
    s = re.sub(r"[^a-zàâäéèêëïîôöùûüç ]", "", str(raw).strip().lower()).strip()
    return mapping.get(s)


def parse_amount(raw: str | None) -> float | None:
    """Montant brut : '55', '55.3', '55,3' -> float >= 0. None si vide/invalide."""
    if raw is None:
        return None
    s = str(raw).strip().replace(",", ".")
    if not s:
        return None
    try:
        v = float(s)
    except ValueError:
        return None
    return v if v >= 0 else None


def parse_count(raw: str | None) -> int | None:
    if raw is None:
        return None
    s = str(raw).strip()
    if not s:
        return None
    try:
        v = int(float(s.replace(",", ".")))
    except ValueError:
        return None
    return v if v >= 0 else None


def _pick(row: dict, cols: tuple[str, ...]) -> str | None:
    lower = {k.lower().strip(): v for k, v in row.items()}
    for c in cols:
        if c in lower and lower[c] not in (None, ""):
            return lower[c]
    return None


def parse_csv(path: str) -> list[InvRecord]:
    out: list[InvRecord] = []
    with open(path, newline="", encoding="utf-8-sig") as f:
        for row in csv.DictReader(f):
            name = _pick(row, NAME_COLS)
            if not name:
                continue
            rec = InvRecord(
                company=name.strip(),
                responsible_policy=parse_status(_pick(row, POLICY_COLS), POLICY_STATUS),
                sustainable_finance=parse_status(_pick(row, FINANCE_COLS), FINANCE_STATUS),
                fossil_financing=parse_amount(_pick(row, FOSSIL_COLS)),
                controversial_holdings=parse_count(_pick(row, HOLDINGS_COLS)),
            )
            if (rec.responsible_policy or rec.sustainable_finance
                    or rec.fossil_financing is not None or rec.controversial_holdings is not None):
                out.append(rec)
    return out


def match_company(entity: dict, records: list[InvRecord]) -> InvRecord | None:
    q = entity.get("display_name") or entity.get("legal_name") or entity.get("slug") or ""
    for r in records:
        if is_strong_match(q, r.company):
            return r
    return None
