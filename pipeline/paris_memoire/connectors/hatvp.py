"""Connecteur HATVP — répertoire des représentants d'intérêts (open data AGORA).

Données : https://www.hatvp.fr/agora/opendata/ (JSON volumineux ; à télécharger
une fois en local, le script d'import lit le fichier).

Produit deux indicateurs :
  * GEO_LOBBYING_TRANSP (binary)      : l'organisation est inscrite au répertoire.
  * GEO_LOBBYING_SPEND  (quantitatif) : dépenses de lobbying déclarées
    (point médian de la fourchette déclarée), contextuel.

Matching : SIREN exact d'abord (fiable), sinon nom en correspondance nette.
"""
from __future__ import annotations

import json
import re
from dataclasses import dataclass
from typing import Any

from ..normalize.names import is_strong_match

HATVP_SOURCE_URL = "https://www.hatvp.fr/le-repertoire/"


@dataclass
class HatvpOrg:
    denomination: str
    siren: str | None
    spend_mid: float | None      # point médian de la fourchette déclarée (€)
    year: str | None             # exercice le plus récent


def _extract_amount_mid(text: str | None) -> float | None:
    """Point médian des montants trouvés dans une fourchette déclarée.

    Ex: ">= 100 000 € et < 200 000 €" -> 150000.
    Robuste aux espaces (fines, insécables) et ignore ce qui ressemble à une
    année (1990-2035) pour ne pas polluer le montant.
    """
    if not text:
        return None
    # un "nombre" = suite de chiffres séparés par espaces (tous types) ou points
    raw = re.findall(r"\d(?:[\s.\u00a0\u202f]*\d)*", text)
    nums = [float(re.sub(r"\D", "", n)) for n in raw]
    nums = [n for n in nums
            if n >= 100 and not (1990 <= n <= 2035)]  # filtre parasites + années
    if not nums:
        return None
    return sum(nums) / len(nums)


def parse_registry(data: dict[str, Any] | list[Any]) -> list[HatvpOrg]:
    """Parse tolérant du JSON AGORA (structure sujette à variations)."""
    if isinstance(data, dict):
        items = data.get("publications") or data.get("resultats") or []
    else:
        items = data
    orgs: list[HatvpOrg] = []
    for it in items:
        if not isinstance(it, dict):
            continue
        denomination = it.get("denomination") or it.get("nomUsage") or it.get("nom") or ""
        siren = it.get("siren") or it.get("sirenSiret") or it.get("identifiantNational")
        if siren:
            siren = str(siren)[:9]
        # exercice le plus récent avec un montant déclaré
        spend_mid, year = None, None
        for ex in (it.get("exercices") or []):
            amount = _extract_amount_mid(
                ex.get("montantDepense") or ex.get("montant") or ex.get("depenses"))
            if amount is not None:
                y = str(ex.get("anneeFin") or ex.get("annee") or ex.get("dateFin") or "")[:4]
                if year is None or y >= year:
                    spend_mid, year = amount, y or None
        if denomination:
            orgs.append(HatvpOrg(denomination=denomination, siren=siren,
                                 spend_mid=spend_mid, year=year))
    return orgs


def load_registry_file(path: str) -> list[HatvpOrg]:
    with open(path, encoding="utf-8") as f:
        return parse_registry(json.load(f))


def match_org(entity: dict[str, Any], orgs: list[HatvpOrg]) -> HatvpOrg | None:
    """SIREN exact d'abord, sinon nom net. None si doute (conservateur)."""
    siren = entity.get("siren")
    if siren:
        for o in orgs:
            if o.siren and o.siren == str(siren):
                return o
    name = entity.get("legal_name") or entity.get("display_name") or ""
    for o in orgs:
        if is_strong_match(name, o.denomination):
            return o
    return None
