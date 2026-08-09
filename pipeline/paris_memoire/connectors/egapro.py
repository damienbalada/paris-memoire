"""Connecteur Égapro — index d'égalité professionnelle F/H (France).

Open data : https://data.economie.gouv.fr — dataset
« index-egalite-professionnelle-f-h » (API Opendatasoft explore v2, sans clé).

Produit LAB_EGAPRO_INDEX (note /100, nature=result, tier regulatory).
Matching par SIREN exact uniquement : la donnée est indexée par SIREN, on ne
tente pas de matching par nom (trop ambigu sur les raisons sociales).
"""
from __future__ import annotations

import csv
from dataclasses import dataclass
from typing import Any

import httpx

EGAPRO_API = (
    "https://data.economie.gouv.fr/api/explore/v2.1/catalog/datasets/"
    "index-egalite-professionnelle-f-h/records"
)
EGAPRO_SOURCE_URL = "https://egapro.travail.gouv.fr/index-egapro/recherche"


@dataclass
class EgaproRecord:
    siren: str
    raison_sociale: str
    year: str
    note: float          # index /100


def parse_records(payload: dict[str, Any]) -> list[EgaproRecord]:
    """Parse tolérant de la réponse ODS explore v2 (champs sujets à variations)."""
    out: list[EgaproRecord] = []
    for rec in payload.get("results", []):
        if not isinstance(rec, dict):
            continue
        siren = str(rec.get("siren") or "").strip()
        note = rec.get("note_index")
        if note is None:
            note = rec.get("note")
        year = str(rec.get("annee") or rec.get("année") or "").strip()
        if not siren or note is None:
            continue
        try:
            note_f = float(note)
        except (TypeError, ValueError):
            continue
        out.append(EgaproRecord(
            siren=siren,
            raison_sociale=str(rec.get("raison_sociale") or ""),
            year=year,
            note=note_f,
        ))
    return out


SIREN_COLS = ("siren",)
NOTE_COLS = ("note index", "note_index", "note", "index")
YEAR_COLS = ("annee", "année", "year")
NAME_COLS = ("raison_sociale", "raison sociale", "entreprise", "nom")


def _pick(row: dict, cols: tuple[str, ...]) -> str | None:
    lower = {k.lower().strip(): v for k, v in row.items()}
    for c in cols:
        if c in lower and lower[c] not in (None, ""):
            return lower[c]
    return None


def parse_csv(path: str) -> list[EgaproRecord]:
    """Fallback hors-ligne : CSV avec siren + note (+ annee, raison_sociale).

    Même contrat que parse_records : on saute toute ligne sans SIREN ou sans note
    exploitable. Note attendue sur /100.
    """
    out: list[EgaproRecord] = []
    with open(path, newline="", encoding="utf-8-sig") as f:
        for row in csv.DictReader(f):
            siren = (str(_pick(row, SIREN_COLS) or "")).strip()
            note = _pick(row, NOTE_COLS)
            if not siren or note is None:
                continue
            try:
                note_f = float(str(note).replace(",", "."))
            except (TypeError, ValueError):
                continue
            out.append(EgaproRecord(
                siren=siren,
                raison_sociale=str(_pick(row, NAME_COLS) or ""),
                year=(str(_pick(row, YEAR_COLS) or "")).strip(),
                note=note_f,
            ))
    return out


def latest_by_siren(records: list[EgaproRecord]) -> dict[str, EgaproRecord]:
    """Garde, par SIREN, l'enregistrement de l'année la plus récente."""
    best: dict[str, EgaproRecord] = {}
    for r in records:
        cur = best.get(r.siren)
        if cur is None or r.year > cur.year:
            best[r.siren] = r
    return best


def fetch_for_sirens(sirens: list[str], client: httpx.Client | None = None) -> list[EgaproRecord]:
    """Interroge l'API ODS pour une liste de SIREN."""
    if not sirens:
        return []
    c = client or httpx.Client(timeout=30)
    try:
        quoted = ",".join(f'"{s}"' for s in sirens)
        r = c.get(EGAPRO_API, params={"where": f"siren in ({quoted})", "limit": 100})
        r.raise_for_status()
        return parse_records(r.json())
    finally:
        if client is None:
            c.close()
