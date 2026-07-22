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
    recs = [cdp.CdpRecord("Nestlé S.A.", "A-", 0.88)]
    assert cdp.match_company({"display_name": "Nestlé"}, recs) is not None
    assert cdp.match_company({"display_name": "Danone"}, recs) is None


def test_build_rows_group_only():
    entities = [
        {"slug": "nestle", "display_name": "Nestlé", "is_brand": False},
        {"slug": "kitkat", "display_name": "KitKat", "is_brand": True},
    ]
    recs = [cdp.CdpRecord("Nestlé", "A-", 0.88)]
    rows = build_rows(entities, recs, observed_on="2024-01-01")
    assert {r.entity_slug for r in rows} == {"nestle"}
    assert rows[0].indicator_code == "ENV_CDP_CLIMATE"
    assert rows[0].value_type == "ordinal"
    assert rows[0].value_text == "A-"
    assert rows[0].normalized_value == 0.88
    assert rows[0].nature == "result"


def test_parse_csv_skips_unknown(tmp_path):
    p = tmp_path / "cdp.csv"
    p.write_text("company,cdp_climate\nNestlé,A-\nAcme,Z\nBeta,\n", encoding="utf-8")
    recs = cdp.parse_csv(str(p))
    # Acme (grade invalide) et Beta (vide) écartés
    assert [r.company for r in recs] == ["Nestlé"]
