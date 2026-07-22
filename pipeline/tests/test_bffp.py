from paris_memoire.connectors import bffp
from paris_memoire.import_bffp import build_rows


def test_severity_from_rank_is_monotone_decreasing():
    # Pire pollueur (#1) => sévérité la plus haute ; décroît avec le rang.
    assert bffp.severity_from_rank(1) == 0.90
    assert bffp.severity_from_rank(2) == 0.80
    assert bffp.severity_from_rank(3) == 0.75
    assert bffp.severity_from_rank(8) == 0.60
    assert bffp.severity_from_rank(40) == 0.45
    assert bffp.severity_from_rank(200) == 0.35
    ranks = [1, 2, 5, 20, 100]
    sev = [bffp.severity_from_rank(r) for r in ranks]
    assert sev == sorted(sev, reverse=True)  # monotone décroissant


def test_parse_csv_rank_and_band(tmp_path):
    p = tmp_path / "bffp.csv"
    p.write_text(
        "company,rank,band\n"
        "Coca-Cola,1,\n"
        "Danone,,top10\n"
        "Ignorée,,\n",           # ni rang ni bande -> sautée
        encoding="utf-8",
    )
    recs = bffp.parse_csv(str(p))
    by = {r.company: r for r in recs}
    assert set(by) == {"Coca-Cola", "Danone"}
    assert by["Coca-Cola"].severity == 0.90
    assert by["Coca-Cola"].label == "#1 mondial"
    assert by["Danone"].severity == 0.60


def test_build_rows_writes_severity_as_controversy():
    entities = [{"slug": "coca-cola", "display_name": "Coca-Cola", "is_brand": False}]
    recs = [bffp.BffpRecord(company="Coca-Cola", severity=0.90, label="#1 mondial")]
    rows = build_rows(entities, recs, observed_on="2024-01-01")
    assert len(rows) == 1
    r = rows[0]
    assert r.indicator_code == "PLA_POLLUTER"
    assert r.nature == "controversy"          # gate écrit comme controverse
    assert r.normalized_value == 0.90         # sévérité haute pour le pire pollueur
    assert r.entity_slug == "coca-cola"


def test_build_rows_skips_unknown_entity():
    entities = [{"slug": "nestle", "display_name": "Nestlé", "is_brand": False}]
    recs = [bffp.BffpRecord(company="UnknownCo", severity=0.90, label="#1 mondial")]
    assert build_rows(entities, recs, observed_on="2024-01-01") == []
