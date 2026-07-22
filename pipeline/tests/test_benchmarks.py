from paris_memoire.connectors import benchmarks as bm
from paris_memoire.import_benchmarks import build_rows


def test_norm_bbfaw_tier():
    assert bm.norm_bbfaw_tier(1) == 1.0
    assert bm.norm_bbfaw_tier(6) == 0.10
    assert bm.norm_bbfaw_tier(3) == 0.64


def test_parse_tier():
    assert bm.parse_tier("Tier 6") == 6
    assert bm.parse_tier("6") == 6
    assert bm.parse_tier("T3") == 3
    assert bm.parse_tier("") is None
    assert bm.parse_tier(None) is None
    assert bm.parse_tier("Tier 9") is None   # hors 1..6


def test_parse_score():
    assert bm.parse_score("55") == 55.0
    assert bm.parse_score("55/100") == 55.0
    assert bm.parse_score("80 %") == 80.0
    assert bm.parse_score("49,5") == 49.5
    assert bm.parse_score("") is None
    assert bm.parse_score("150") is None     # aberrant


def test_norm_score():
    assert bm.norm_score(55) == 0.55
    assert bm.norm_score(120) == 1.0
    assert bm.norm_score(-5) == 0.0


def test_parse_csv_unknown_benchmark(tmp_path):
    p = tmp_path / "x.csv"
    p.write_text("company,score\nA,10\n", encoding="utf-8")
    try:
        bm.parse_csv(str(p), "nope")
        assert False, "devait lever ValueError"
    except ValueError:
        pass


def test_parse_and_build_bbfaw(tmp_path):
    p = tmp_path / "bbfaw.csv"
    p.write_text("company,tier\nStarbucks,Tier 6\nUnknownCo,Tier 2\n", encoding="utf-8")
    rows = bm.parse_csv(str(p), "bbfaw")
    assert len(rows) == 2
    assert rows[0].indicator_code == "ANI_BBFAW_TIER"
    assert rows[0].value_type == "ordinal"
    assert rows[0].normalized_value == 0.10

    entities = [{"slug": "starbucks", "display_name": "Starbucks", "is_brand": False}]
    ev = build_rows(entities, rows, observed_on="2024-01-01")
    # UnknownCo sans entité -> écarté
    assert {r.entity_slug for r in ev} == {"starbucks"}
    assert ev[0].value_text == "Tier 6"
    assert ev[0].nature == "result"


def test_build_knowthechain_and_fti(tmp_path):
    entities = [
        {"slug": "gucci", "display_name": "Gucci", "is_brand": True},
        {"slug": "adidas", "display_name": "Adidas", "is_brand": False},
    ]
    ktc = tmp_path / "ktc.csv"
    ktc.write_text("company,score\nAdidas,55\n", encoding="utf-8")
    fti = tmp_path / "fti.csv"
    fti.write_text("brand,score\nGucci,80\n", encoding="utf-8")

    ev_ktc = build_rows(entities, bm.parse_csv(str(ktc), "knowthechain"), observed_on="2024-01-01")
    assert ev_ktc[0].indicator_code == "SUP_KNOWTHECHAIN"
    assert ev_ktc[0].value_numeric == 55.0
    assert ev_ktc[0].normalized_value == 0.55

    # FTI peut noter une MARQUE (Gucci) -> autorisé
    ev_fti = build_rows(entities, bm.parse_csv(str(fti), "fti"), observed_on="2024-01-01")
    assert ev_fti[0].entity_slug == "gucci"
    assert ev_fti[0].indicator_code == "SUP_FTI_SCORE"
    assert ev_fti[0].normalized_value == 0.80
