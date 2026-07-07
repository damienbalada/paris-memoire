import textwrap

import pytest

from paris_memoire.connectors.yale_russia import YaleRow, match_company, parse_csv
from paris_memoire.import_yale import build_rows


def _write_csv(tmp_path, content: str):
    p = tmp_path / "yale.csv"
    p.write_text(textwrap.dedent(content), encoding="utf-8")
    return str(p)


def test_parse_csv_with_grades(tmp_path):
    path = _write_csv(tmp_path, """\
        Name,Grade
        Kering,A
        Hermes,B
        Unknown Co,X
    """)
    rows = parse_csv(path)
    assert [(r.company, r.value) for r in rows] == [("Kering", 1.0), ("Hermes", 0.7)]


def test_parse_csv_with_status_column(tmp_path):
    path = _write_csv(tmp_path, """\
        Company,Action
        Richemont SA,Suspension of operations
        Digging Co,digging in
    """)
    rows = parse_csv(path)
    assert rows[0].value == 0.7
    assert rows[1].value == 0.0


def test_parse_csv_missing_columns(tmp_path):
    path = _write_csv(tmp_path, "Foo,Bar\n1,2\n")
    with pytest.raises(ValueError):
        parse_csv(path)


def test_match_uses_display_name():
    rows = [YaleRow(company="Kering", value=1.0, label="A")]
    entity = {"legal_name": "Kering SA", "display_name": "Kering"}
    assert match_company(entity, rows) is not None


def test_build_rows_skips_brands():
    yale = [YaleRow(company="Kering", value=1.0, label="A")]
    entities = [
        {"slug": "kering", "legal_name": "Kering SA", "display_name": "Kering", "is_brand": False},
        {"slug": "gucci", "legal_name": "Guccio Gucci SpA", "display_name": "Gucci", "is_brand": True},
    ]
    rows = build_rows(entities, yale, observed_on="2026-07-07")
    assert len(rows) == 1
    assert rows[0].entity_slug == "kering"
    assert rows[0].normalized_value == 1.0
