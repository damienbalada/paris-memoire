"""Connecteur Gouvernance — composition du conseil (mixité + indépendance).

Source : données de gouvernance publiées (déclarations CSRD/ESRS, documents de
référence). Ce module est PUR (parsing + normalisation + matching) ; l'appel
réseau/DB se fait via import_governance.py.

Produit :
  * GOV_BOARD_GENDER   — part de femmes au conseil, normalisée vers la parité.
  * GOV_BOARD_INDEP    — part d'administrateurs indépendants.

Normalisation :
  * mixité   : parité (50 %) = 1.0 ; en dessous, proportionnel (40 % -> 0.8).
               (on ne « sur-récompense » pas au-delà de la parité : plafonné à 1.0)
  * indép.   : part directe (0..1), plus c'est haut, mieux c'est.

Matching de noms conservateur (is_strong_match) : en cas de doute, on saute.
"""
from __future__ import annotations

import csv
from dataclasses import dataclass

from ..normalize.names import is_strong_match

GOV_SOURCE_URL = "https://www.esma.europa.eu/"  # placeholder ; l'URL réelle vient du dataset

NAME_COLS = ("company", "name", "entity", "société", "nom")
WOMEN_COLS = ("board_women_share", "women_share", "women", "femmes", "board_women_pct", "share_women")
INDEP_COLS = ("board_independent_share", "independent_share", "independents", "independance", "indep_pct")


@dataclass
class GovRecord:
    company: str
    women_share: float | None       # fraction 0..1
    independent_share: float | None  # fraction 0..1


def parse_share(raw: str | None) -> float | None:
    """Interprète '40', '40 %', '0.4' -> 0.40. None si vide/invalide."""
    if raw is None:
        return None
    s = str(raw).strip().replace("%", "").replace(",", ".").strip()
    if not s:
        return None
    try:
        v = float(s)
    except ValueError:
        return None
    if v > 1.0:            # exprimé en pourcentage
        v = v / 100.0
    if v < 0 or v > 1.5:   # garde-fou : valeur aberrante
        return None
    return min(v, 1.0)


def _pick(row: dict, cols: tuple[str, ...]) -> str | None:
    lower = {k.lower().strip(): v for k, v in row.items()}
    for c in cols:
        if c in lower and lower[c] not in (None, ""):
            return lower[c]
    return None


def parse_csv(path: str) -> list[GovRecord]:
    out: list[GovRecord] = []
    with open(path, newline="", encoding="utf-8") as f:
        for row in csv.DictReader(f):
            name = _pick(row, NAME_COLS)
            if not name:
                continue
            out.append(GovRecord(
                company=name.strip(),
                women_share=parse_share(_pick(row, WOMEN_COLS)),
                independent_share=parse_share(_pick(row, INDEP_COLS)),
            ))
    return out


def norm_gender(share: float) -> float:
    """Parité (0.5) = 1.0 ; proportionnel en dessous ; plafonné à 1.0."""
    return max(0.0, min(share / 0.5, 1.0))


def norm_independence(share: float) -> float:
    return max(0.0, min(share, 1.0))


def match_company(entity: dict, records: list[GovRecord]) -> GovRecord | None:
    """1er enregistrement dont le nom correspond nettement, sinon None."""
    q = entity.get("display_name") or entity.get("legal_name") or entity.get("slug") or ""
    for r in records:
        if is_strong_match(q, r.company):
            return r
    return None
