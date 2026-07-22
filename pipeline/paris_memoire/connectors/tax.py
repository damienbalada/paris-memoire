"""Connecteur Fiscalité — transparence pays-par-pays, taux effectif, paradis fiscaux.

Source : données fiscales publiées (déclaration pays-par-pays / CbCR, états
financiers & document d'enregistrement universel, analyses Tax Justice Network).
Module PUR (parsing + interprétation + matching) ; l'appel réseau/DB se fait
via import_tax.py.

Produit trois indicateurs :
  * TAX_CBCR_PUBLISHED  — reporting pays-par-pays public (oui/non), binaire.
  * TAX_EFFECTIVE_RATE  — taux effectif d'imposition (%), quantitatif.
  * TAX_HAVEN_PRESENCE  — nb d'entités en juridictions à faible imposition, quantitatif.

Normalisation :
  * CbCR : oui -> 1.0, non -> 0.0 (fait binaire, normalisé ici).
  * Taux effectif & paradis fiscaux : on fournit la VALEUR BRUTE et on laisse
    le moteur (scoring.ts) calculer le percentile intra-secteur — c'est lui qui
    applique la direction (taux effectif : higher_better ; paradis : lower_better).
    Normaliser à la main ici fausserait la comparaison sectorielle.

Matching de noms conservateur (is_strong_match) : en cas de doute, on saute.
"""
from __future__ import annotations

import csv
from dataclasses import dataclass

from ..normalize.names import is_strong_match

# Sources par défaut (surchargées côté import). Doivent exister dans `sources`.
CBCR_SOURCE = "CBCR"            # regulatory — déclaration pays-par-pays
ETR_SOURCE = "AMF"             # regulatory — document d'enregistrement universel / états financiers
HAVEN_SOURCE = "TAX_JUSTICE"  # audited_ngo — Tax Justice Network

NAME_COLS = ("company", "name", "entity", "société", "nom")
CBCR_COLS = ("cbcr_published", "cbcr", "country_by_country", "cbcr_public", "reporting_pays_par_pays")
ETR_COLS = ("effective_tax_rate", "etr", "effective_rate", "taux_effectif", "taux_imposition")
HAVEN_COLS = ("haven_entities", "tax_haven_entities", "entities_low_tax", "paradis_fiscaux", "nb_paradis")

_TRUE = {"true", "1", "oui", "yes", "y", "x", "publié", "publie", "vrai"}
_FALSE = {"false", "0", "non", "no", "n", "absent", "faux"}


@dataclass
class TaxRecord:
    company: str
    cbcr_published: bool | None     # reporting pays-par-pays public
    effective_rate: float | None    # taux effectif d'imposition, en % (peut être négatif)
    haven_entities: int | None      # nb d'entités en juridictions à faible imposition


def parse_bool(raw: str | None) -> bool | None:
    """'oui'/'true'/'1'/'x' -> True ; 'non'/'false'/'0' -> False ; sinon None."""
    if raw is None:
        return None
    s = str(raw).strip().lower()
    if s in _TRUE:
        return True
    if s in _FALSE:
        return False
    return None


def parse_rate(raw: str | None) -> float | None:
    """'17,4' / '17.4 %' -> 17.4. Négatif autorisé (crédits d'impôt). None si vide/aberrant."""
    if raw is None:
        return None
    s = str(raw).strip().replace("%", "").replace(",", ".").strip()
    if not s:
        return None
    try:
        v = float(s)
    except ValueError:
        return None
    if abs(v) > 100:   # garde-fou : un taux effectif hors [-100, 100] % est aberrant
        return None
    return v


def parse_count(raw: str | None) -> int | None:
    """Nombre entier >= 0. None si vide/invalide/négatif."""
    if raw is None:
        return None
    s = str(raw).strip().replace(",", "").strip()
    if not s:
        return None
    try:
        v = int(float(s))
    except ValueError:
        return None
    return v if v >= 0 else None


def _pick(row: dict, cols: tuple[str, ...]) -> str | None:
    lower = {k.lower().strip(): v for k, v in row.items()}
    for c in cols:
        if c in lower and lower[c] not in (None, ""):
            return lower[c]
    return None


def parse_csv(path: str) -> list[TaxRecord]:
    out: list[TaxRecord] = []
    with open(path, newline="", encoding="utf-8-sig") as f:
        for row in csv.DictReader(f):
            name = _pick(row, NAME_COLS)
            if not name:
                continue
            out.append(TaxRecord(
                company=name.strip(),
                cbcr_published=parse_bool(_pick(row, CBCR_COLS)),
                effective_rate=parse_rate(_pick(row, ETR_COLS)),
                haven_entities=parse_count(_pick(row, HAVEN_COLS)),
            ))
    return out


def match_company(entity: dict, records: list[TaxRecord]) -> TaxRecord | None:
    """1er enregistrement dont le nom correspond nettement, sinon None."""
    q = entity.get("display_name") or entity.get("legal_name") or entity.get("slug") or ""
    for r in records:
        if is_strong_match(q, r.company):
            return r
    return None
