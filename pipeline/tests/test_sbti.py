import textwrap

import pytest

from paris_memoire.connectors.sbti import SbtiRow, match_company, parse_csv
from paris_memoire.import_sbti import build_rows


def _write_csv(tmp_path, content: str):
    p = tmp_path / "sbti.csv"
    p.write_text(textwrap.dedent(content), encoding="utf-8")
    return str(p)


def test_parse_csv_statuses(tmp_path):
    path = _write_csv(tmp_path, """\
        Company Name,Near term - Target Status,Near term - Target Classification
        Kering,Targets Set,1.5°C
        Hermes International,Targets Set,Well-below 2°C
        Chanel Limited,Committed,
        Removed Co,Removed,
        Unknown Co,Something Else,
    """)
    rows = parse_csv(path)
    by_company = {r.company: r for r in rows}
    assert by_company["Kering"].normalized_value == 1.0
    assert by_company["Kering"].nature == "result"
    assert by_company["Hermes International"].normalized_value == 0.6
    assert by_company["Chanel Limited"].nature == "commitment"
    assert by_company["Chanel Limited"].normalized_value == 1.0  # le moteur appliquera ×0.4 + plafond
    assert by_company["Removed Co"].normalized_value == 0.0
    assert "Unknown Co" not in by_company


def test_parse_csv_missing_columns(tmp_path):
    path = _write_csv(tmp_path, "Foo,Bar\n1,2\n")
    with pytest.raises(ValueError):
        parse_csv(path)


def test_match_conservative():
    rows = [SbtiRow(company="Kering", normalized_value=1.0, nature="result", label="Targets Set")]
    assert match_company({"legal_name": "Kering SA", "display_name": "Kering"}, rows) is not None
    assert match_company({"legal_name": "L'Oréal", "display_name": "L'Oréal"}, rows) is None


def test_build_rows_skips_brands_and_sets_nature():
    sbti_rows = [SbtiRow(company="Kering", normalized_value=1.0, nature="result", label="Targets Set")]
    entities = [
        {"slug": "kering", "legal_name": "Kering SA", "display_name": "Kering", "is_brand": False},
        {"slug": "gucci", "legal_name": "Guccio Gucci SpA", "display_name": "Gucci", "is_brand": True},
    ]
    rows = build_rows(entities, sbti_rows, observed_on="2026-07-14")
    assert len(rows) == 1
    assert rows[0].indicator_code == "ENV_SBTI_VALIDATED"
    assert rows[0].nature == "result"
