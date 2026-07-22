from paris_memoire.connectors import governance as gov
from paris_memoire.import_governance import build_rows


def test_parse_share_formats():
    assert gov.parse_share("40") == 0.40
    assert gov.parse_share("40 %") == 0.40
    assert gov.parse_share("0.4") == 0.40
    assert gov.parse_share("55,5") == 0.555
    assert gov.parse_share("") is None
    assert gov.parse_share(None) is None
    assert gov.parse_share("n/a") is None
    assert gov.parse_share("999") is None   # aberrant -> None


def test_norm_gender_parity():
    assert gov.norm_gender(0.5) == 1.0
    assert gov.norm_gender(0.4) == 0.8
    assert gov.norm_gender(0.0) == 0.0
    assert gov.norm_gender(0.6) == 1.0      # plafonné à la parité


def test_norm_independence():
    assert gov.norm_independence(0.75) == 0.75
    assert gov.norm_independence(1.2) == 1.0


def test_match_company_conservative():
    recs = [gov.GovRecord("L'Oréal S.A.", 0.46, 0.55)]
    assert gov.match_company({"display_name": "L'Oréal"}, recs) is not None
    assert gov.match_company({"display_name": "Nestlé"}, recs) is None


def test_build_rows_group_only_and_indicators():
    entities = [
        {"slug": "loreal", "display_name": "L'Oréal", "is_brand": False},
        {"slug": "some-brand", "display_name": "L'Oréal Paris", "is_brand": True},
    ]
    recs = [gov.GovRecord("L'Oréal", 0.46, 0.60)]
    rows = build_rows(entities, recs, observed_on="2024-01-01")
    # marque ignorée -> seules des lignes pour le groupe
    assert {r.entity_slug for r in rows} == {"loreal"}
    by_ind = {r.indicator_code: r for r in rows}
    assert by_ind["GOV_BOARD_GENDER"].value_numeric == 46
    assert abs(by_ind["GOV_BOARD_GENDER"].normalized_value - 0.92) < 1e-9  # 0.46/0.5
    assert by_ind["GOV_BOARD_INDEP"].normalized_value == 0.60
    assert all(r.nature == "result" for r in rows)


def test_build_rows_skips_missing_values():
    entities = [{"slug": "x", "display_name": "X Corp", "is_brand": False}]
    recs = [gov.GovRecord("X Corp", None, None)]
    assert build_rows(entities, recs, observed_on="2024-01-01") == []
