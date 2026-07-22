from paris_memoire.connectors import tax
from paris_memoire.import_tax import build_rows


def test_parse_bool():
    assert tax.parse_bool("oui") is True
    assert tax.parse_bool("TRUE") is True
    assert tax.parse_bool("1") is True
    assert tax.parse_bool("non") is False
    assert tax.parse_bool("0") is False
    assert tax.parse_bool("") is None
    assert tax.parse_bool(None) is None
    assert tax.parse_bool("peut-être") is None


def test_parse_rate():
    assert tax.parse_rate("17,4") == 17.4
    assert tax.parse_rate("17.4 %") == 17.4
    assert tax.parse_rate("-2.1") == -2.1     # crédit d'impôt : négatif autorisé
    assert tax.parse_rate("") is None
    assert tax.parse_rate("n/a") is None
    assert tax.parse_rate("250") is None      # aberrant


def test_parse_count():
    assert tax.parse_count("12") == 12
    assert tax.parse_count("0") == 0
    assert tax.parse_count("") is None
    assert tax.parse_count("-3") is None      # négatif -> None
    assert tax.parse_count("abc") is None


def test_match_company_conservative():
    recs = [tax.TaxRecord("Kering S.A.", True, 25.1, 3)]
    assert tax.match_company({"display_name": "Kering"}, recs) is not None
    assert tax.match_company({"display_name": "Hermès"}, recs) is None


def test_build_rows_group_only_raw_quantitatives():
    entities = [
        {"slug": "kering", "display_name": "Kering", "is_brand": False},
        {"slug": "gucci", "display_name": "Gucci", "is_brand": True},
    ]
    recs = [tax.TaxRecord("Kering", True, 25.1, 4)]
    rows = build_rows(entities, recs, observed_on="2024-01-01")
    # marque ignorée -> seul le groupe
    assert {r.entity_slug for r in rows} == {"kering"}
    by = {r.indicator_code: r for r in rows}
    # CbCR : binaire, normalisé ici
    assert by["TAX_CBCR_PUBLISHED"].value_boolean is True
    assert by["TAX_CBCR_PUBLISHED"].normalized_value == 1.0
    # quantitatifs : valeur brute, normalized laissé au moteur (percentile)
    assert by["TAX_EFFECTIVE_RATE"].value_numeric == 25.1
    assert by["TAX_EFFECTIVE_RATE"].normalized_value is None
    assert by["TAX_HAVEN_PRESENCE"].value_numeric == 4.0
    assert by["TAX_HAVEN_PRESENCE"].normalized_value is None
    assert all(r.nature == "result" for r in rows)


def test_build_rows_cbcr_false_is_kept():
    entities = [{"slug": "acme", "display_name": "Acme Corp", "is_brand": False}]
    recs = [tax.TaxRecord("Acme Corp", False, None, None)]
    rows = build_rows(entities, recs, observed_on="2024-01-01")
    assert len(rows) == 1
    assert rows[0].indicator_code == "TAX_CBCR_PUBLISHED"
    assert rows[0].value_boolean is False
    assert rows[0].normalized_value == 0.0


def test_build_rows_skips_all_missing():
    entities = [{"slug": "x", "display_name": "X Corp", "is_brand": False}]
    recs = [tax.TaxRecord("X Corp", None, None, None)]
    assert build_rows(entities, recs, observed_on="2024-01-01") == []
