from paris_memoire.connectors import investments as inv
from paris_memoire.import_investments import build_rows


def test_parse_status_policy():
    assert inv.parse_status("signataire", inv.POLICY_STATUS) == ("signataire UN PRI", 1.0, "result")
    assert inv.parse_status("Politique", inv.POLICY_STATUS) == ("politique déclarée", 0.5, "policy")
    assert inv.parse_status("absente", inv.POLICY_STATUS) == ("absente", 0.0, "result")
    assert inv.parse_status("", inv.POLICY_STATUS) is None
    assert inv.parse_status("bla", inv.POLICY_STATUS) is None


def test_parse_status_finance():
    assert inv.parse_status("framework", inv.FINANCE_STATUS) == ("cadre structuré", 1.0, "result")
    assert inv.parse_status("ponctuel", inv.FINANCE_STATUS) == ("émissions ponctuelles", 0.5, "result")
    assert inv.parse_status("aucun", inv.FINANCE_STATUS) == ("aucune", 0.0, "result")


def test_parse_amount_and_count():
    assert inv.parse_amount("55,3") == 55.3
    assert inv.parse_amount("0") == 0.0
    assert inv.parse_amount("-1") is None
    assert inv.parse_amount("") is None
    assert inv.parse_count("4") == 4
    assert inv.parse_count("-2") is None


def test_build_rows_group_only_quantitatives_raw():
    entities = [
        {"slug": "bnp-paribas", "display_name": "BNP Paribas", "is_brand": False},
        {"slug": "some-brand", "display_name": "BNP Paribas Retail", "is_brand": True},
    ]
    recs = [inv.InvRecord(
        company="BNP Paribas",
        responsible_policy=("politique déclarée", 0.5, "policy"),
        fossil_financing=55.0,
        controversial_holdings=3,
    )]
    rows = build_rows(entities, recs, observed_on="2024-01-01")
    assert {r.entity_slug for r in rows} == {"bnp-paribas"}  # marque ignorée
    by = {r.indicator_code: r for r in rows}
    assert by["INV_RESPONSIBLE_POLICY"].normalized_value == 0.5
    assert by["INV_RESPONSIBLE_POLICY"].nature == "policy"
    # quantitatifs bruts, normalized laissé au moteur
    assert by["INV_FOSSIL_FINANCING"].value_numeric == 55.0
    assert by["INV_FOSSIL_FINANCING"].normalized_value is None
    assert by["INV_CONTROVERSIAL_HOLDINGS"].value_numeric == 3.0
    assert by["INV_CONTROVERSIAL_HOLDINGS"].normalized_value is None


def test_parse_csv_skips_empty_rows(tmp_path):
    p = tmp_path / "inv.csv"
    p.write_text(
        "company,responsible_policy,fossil_financing\n"
        "BNP Paribas,signataire,55\n"
        "VideCorp,,\n",     # aucune donnée exploitable -> sautée
        encoding="utf-8",
    )
    recs = inv.parse_csv(str(p))
    assert [r.company for r in recs] == ["BNP Paribas"]
    assert recs[0].responsible_policy == ("signataire UN PRI", 1.0, "result")
    assert recs[0].fossil_financing == 55.0
