from paris_memoire.connectors.hatvp import (
    HatvpOrg,
    _extract_amount_mid,
    match_org,
    parse_registry,
)
from paris_memoire.import_hatvp import build_rows

FIXTURE = {
    "publications": [
        {
            "denomination": "KERING",
            "siren": "552075020",
            "exercices": [
                {"anneeFin": "2023", "montantDepense": ">= 100 000 € et < 200 000 €"},
                {"anneeFin": "2024", "montantDepense": ">= 200 000 € et < 300 000 €"},
            ],
        },
        {
            "denomination": "TOTALLY UNRELATED CORP",
            "sirenSiret": "123456789",
            "exercices": [],
        },
    ]
}


def test_extract_amount_mid():
    assert _extract_amount_mid(">= 100 000 € et < 200 000 €") == 150000.0
    assert _extract_amount_mid(None) is None
    assert _extract_amount_mid("aucun montant") is None


def test_extract_amount_mid_robust():
    # espaces insécables (U+00A0) et fines (U+202F)
    assert _extract_amount_mid("100 000 à 200 000 €") == 150000.0
    # une année dans le texte ne doit pas polluer le montant
    assert _extract_amount_mid("exercice 2023 : >= 100 000 € et < 200 000 €") == 150000.0
    # rien que des années -> pas de montant
    assert _extract_amount_mid("exercice 2023") is None


def test_parse_registry_takes_latest_exercice():
    orgs = parse_registry(FIXTURE)
    assert len(orgs) == 2
    kering = orgs[0]
    assert kering.siren == "552075020"
    assert kering.year == "2024"
    assert kering.spend_mid == 250000.0


def test_match_by_siren_beats_name():
    orgs = [HatvpOrg(denomination="NOM TROMPEUR", siren="552075020", spend_mid=None, year=None)]
    entity = {"legal_name": "Kering SA", "siren": "552075020"}
    assert match_org(entity, orgs) is not None


def test_match_conservative_none():
    orgs = [HatvpOrg(denomination="TOTALLY UNRELATED", siren=None, spend_mid=None, year=None)]
    entity = {"legal_name": "Hermès International SCA", "siren": None}
    assert match_org(entity, orgs) is None


def test_build_rows_produces_transp_and_spend():
    orgs = parse_registry(FIXTURE)
    entities = [{"slug": "kering", "legal_name": "Kering SA", "siren": "552075020"}]
    rows = build_rows(entities, orgs, observed_on="2026-07-07")
    codes = {r.indicator_code for r in rows}
    assert codes == {"GEO_LOBBYING_TRANSP", "GEO_LOBBYING_SPEND"}
    spend = next(r for r in rows if r.indicator_code == "GEO_LOBBYING_SPEND")
    assert spend.value_numeric == 250000.0
