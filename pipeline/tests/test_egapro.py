from paris_memoire.connectors.egapro import EgaproRecord, latest_by_siren, parse_records
from paris_memoire.import_egapro import build_rows

PAYLOAD = {
    "results": [
        {"siren": "552075020", "raison_sociale": "KERING", "annee": "2023", "note_index": 91},
        {"siren": "552075020", "raison_sociale": "KERING", "annee": "2024", "note_index": 94},
        {"siren": "999999999", "raison_sociale": "SANS NOTE", "annee": "2024"},  # note manquante
        {"siren": "", "annee": "2024", "note_index": 80},                          # siren manquant
    ]
}


def test_parse_records_skips_incomplete():
    recs = parse_records(PAYLOAD)
    assert len(recs) == 2
    assert all(r.siren == "552075020" for r in recs)


def test_latest_by_siren_keeps_most_recent():
    recs = parse_records(PAYLOAD)
    best = latest_by_siren(recs)
    assert best["552075020"].year == "2024"
    assert best["552075020"].note == 94.0


def test_build_rows_normalizes_over_100():
    by_siren = {"552075020": EgaproRecord(siren="552075020", raison_sociale="KERING", year="2024", note=94)}
    entities = [
        {"slug": "kering", "siren": "552075020"},
        {"slug": "hermes", "siren": "572012051"},   # pas dans les résultats
        {"slug": "chanel", "siren": None},          # pas de siren
    ]
    rows = build_rows(entities, by_siren)
    assert len(rows) == 1
    r = rows[0]
    assert r.entity_slug == "kering"
    assert r.normalized_value == 0.94
    assert r.observed_on == "2024-03-01"
