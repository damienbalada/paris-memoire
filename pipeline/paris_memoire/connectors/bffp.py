"""Connecteur BFFP — Break Free From Plastic (audits de marques).

Alimente l'indicateur-gate PLA_POLLUTER (pilier Plastique). Module PUR :
parsing + normalisation + matching ; l'accès réseau/DB via import_bffp.py.

Sémantique (⚠️ subtile — cf. scoring.ts / evaluateIndicator) : PLA_POLLUTER est
écrit comme une CONTROVERSE. Le moteur en tire le plafond de la dimension via sa
logique de controverse : `plafond = 0.5 × (1 − sévérité × poids_tier)`. Donc
`normalized_value` encode la **SÉVÉRITÉ** de la pollution (haute = fort pollueur),
et le moteur produit un plafond d'autant plus BAS que la sévérité est haute.
  #1 mondial (sévérité 0.90, tier audited_ngo 0.8) → plafond ≈ 0.14 (note bridée à D-).
  top 10     (sévérité 0.60)                        → plafond ≈ 0.26.
Ne PAS confondre avec un plafond direct : ici on fournit la sévérité, pas le plafond.

Entrée : classement BFFP « Top Global Polluters ». On accepte un rang numérique
(`rank`) ou, à défaut, une bande (`band` : top3 / top10 / top50).
Matching de noms conservateur (les audits nomment des marques ou des groupes).
"""
from __future__ import annotations

import csv
import re
from dataclasses import dataclass

from ..normalize.names import is_strong_match

BFFP_SOURCE_URL = "https://www.breakfreefromplastic.org/brandaudit/"

NAME_COLS = ("company", "name", "brand", "marque", "entity", "société", "nom")
RANK_COLS = ("rank", "rang", "position", "classement")
BAND_COLS = ("band", "bande", "tier", "categorie", "catégorie")

# Bandes -> sévérité (utilisé si pas de rang précis). Aligné sur la curation.
BAND_SEVERITY = {"top3": 0.75, "top10": 0.60, "top50": 0.45}


@dataclass
class BffpRecord:
    company: str
    severity: float       # SÉVÉRITÉ de la pollution (haute = fort pollueur)
    label: str            # étiquette lisible (traçabilité), ex. '#1 mondial'


def severity_from_rank(rank: int) -> float:
    """Rang BFFP -> sévérité. #1 = 0.90 ; décroît quand le rang augmente."""
    if rank <= 1:
        return 0.90
    if rank == 2:
        return 0.80
    if rank == 3:
        return 0.75
    if rank <= 10:
        return 0.60
    if rank <= 50:
        return 0.45
    return 0.35


def _label_from_rank(rank: int) -> str:
    if rank <= 3:
        return f"#{rank} mondial"
    if rank <= 10:
        return "top 10"
    if rank <= 50:
        return "top 50"
    return f"#{rank}"


def parse_rank(raw: str | None) -> int | None:
    if raw is None:
        return None
    m = re.search(r"\d+", str(raw))
    return int(m.group()) if m else None


def _pick(row: dict, cols: tuple[str, ...]) -> str | None:
    lower = {k.lower().strip(): v for k, v in row.items()}
    for c in cols:
        if c in lower and lower[c] not in (None, ""):
            return lower[c]
    return None


def _band_severity(raw: str | None) -> tuple[float, str] | None:
    if raw is None:
        return None
    s = re.sub(r"[^a-z0-9]", "", str(raw).lower())
    if s in BAND_SEVERITY:
        return BAND_SEVERITY[s], {"top3": "top 3", "top10": "top 10", "top50": "top 50"}[s]
    return None


def parse_csv(path: str) -> list[BffpRecord]:
    out: list[BffpRecord] = []
    with open(path, newline="", encoding="utf-8-sig") as f:
        for row in csv.DictReader(f):
            name = _pick(row, NAME_COLS)
            if not name:
                continue
            rank = parse_rank(_pick(row, RANK_COLS))
            if rank is not None:
                out.append(BffpRecord(company=name.strip(),
                                      severity=severity_from_rank(rank),
                                      label=_label_from_rank(rank)))
                continue
            band = _band_severity(_pick(row, BAND_COLS))
            if band is not None:
                severity, label = band
                out.append(BffpRecord(company=name.strip(), severity=severity, label=label))
    return out


def match_entity(record: BffpRecord, entities: list[dict]) -> dict | None:
    """Cherche l'entité (groupe OU marque) dont le nom correspond nettement."""
    for e in entities:
        for key in ("display_name", "legal_name", "slug"):
            val = e.get(key)
            if val and is_strong_match(record.company, val):
                return e
    return None
