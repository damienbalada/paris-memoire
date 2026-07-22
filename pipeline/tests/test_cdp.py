from paris_memoire.connectors import cdp
from paris_memoire.import_cdp import build_rows


def test_parse_grade():
    assert cdp.parse_grade("A") == ("A", 1.0)
    assert cdp.parse_grade("a-") == ("A-", 0.88)
    assert cdp.parse_grade("B") == ("B", 0.75)
    assert cdp.parse_grade("F") == ("F", 0.0)
    assert cdp.parse_grade("A −") == ("A-", 0.88)   # minus unicode + espace
    assert cdp.parse_grade("") is None
    assert cdp.parse_grade(None) is None
    assert cdp.parse_grade("Z") is None             # hors barème


def test_match_company_conservative():
    recs = [cdp.CdpRecord("Nestlé S.A.", climate=("A-", 0.88))]
    assert cdp.match_company({"display_name": "Nestlé"}, recs) is not None
    assert cdp.match_company({"display_name": "Danone"}, recs) is None


def test_build_rows_group_only_climate_and_water():
    entities = [
        {"slug": "nestle", "display_name": "Nestlé", "is_brand": False},
        {"slug": "kitkat", "display_name": "KitKat", "is_brand": True},
    ]
    recs = [cdp.CdpRecord("Nestlé", climate=("A-", 0.88), water=("B", 0.75))]
    rows = build_rows(entities, recs, observed_on="2024-01-01")
    # marque ignorée -> seul le groupe ; deux indicateurs (climat + eau)
    assert {r.entity_slug for r in rows} == {"nestle"}
    by = {r.indicator_code: r for r in rows}
    assert by["ENV_CDP_CLIMATE"].value_text == "A-"
    assert by["ENV_CDP_CLIMATE"].normalized_value == 0.88
    assert by["WAT_CDP"].value_text == "B"
    assert by["WAT_CDP"].normalized_value == 0.75
    assert all(r.value_type == "ordinal" and r.nature == "result" for r in rows)


def test_build_rows_climate_only():
    entities = [{"slug": "danone", "display_name": "Danone", "is_brand": False}]
    recs = [cdp.CdpRecord("Danone", climate=("A", 1.0))]
    rows = build_rows(entities, recs, observed_on="2024-01-01")
    assert [r.indicator_code for r in rows] == ["ENV_CDP_CLIMATE"]


def test_parse_csv_climate_and_water(tmp_path):
    p = tmp_path / "cdp.csv"
    p.write_text(
        "company,cdp_climate,cdp_water\n"
        "Nestlé,A-,B\n"
        "Acme,Z,\n"       # climat invalide, eau vide -> sautée
        "Beta,,A\n",      # eau seule
        encoding="utf-8",
    )
    recs = cdp.parse_csv(str(p))
    by = {r.company: r for r in recs}
    assert set(by) == {"Nestlé", "Beta"}
    assert by["Nestlé"].climate == ("A-", 0.88)
    assert by["Nestlé"].water == ("B", 0.75)
    assert by["Beta"].climate is None
    assert by["Beta"].water == ("A", 1.0)
