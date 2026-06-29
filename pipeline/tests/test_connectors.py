from paris_memoire.connectors.gleif import parse_lei_record
from paris_memoire.connectors.sirene import parse_result


def test_parse_lei_record():
    rec = {
        "id": "969500FU4DRACT9R7M77",
        "attributes": {
            "lei": "969500FU4DRACT9R7M77",
            "entity": {
                "legalName": {"name": "LVMH MOET HENNESSY LOUIS VUITTON"},
                "legalAddress": {"country": "FR"},
            },
        },
    }
    out = parse_lei_record(rec)
    assert out == {
        "lei": "969500FU4DRACT9R7M77",
        "legal_name": "LVMH MOET HENNESSY LOUIS VUITTON",
        "country": "FR",
    }


def test_parse_lei_record_missing_fields():
    out = parse_lei_record({"id": "X", "attributes": {}})
    assert out["lei"] == "X"
    assert out["legal_name"] is None


def test_parse_sirene_result():
    res = {"siren": "775670417", "nom_complet": "LVMH", "nom_raison_sociale": "LVMH"}
    assert parse_result(res) == {"siren": "775670417", "nom": "LVMH"}
