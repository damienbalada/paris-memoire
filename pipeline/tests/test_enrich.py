"""Test du résolveur (connecteurs mockés — aucun appel réseau)."""
from paris_memoire import enrich_entities
from paris_memoire.connectors import gleif, sirene


def test_resolve_entity_fills_lei_and_siren(monkeypatch):
    monkeypatch.setattr(gleif, "search_lei",
                        lambda name, country=None, client=None: [{"lei": "ABC123", "legal_name": "Kering", "country": "FR"}])
    monkeypatch.setattr(gleif, "direct_parent", lambda lei, client=None: None)
    monkeypatch.setattr(sirene, "search_siren",
                        lambda name, client=None: [{"siren": "552075020", "nom": "Kering"}])

    entity = {"legal_name": "Kering SA", "country": "FR", "lei": None, "siren": None}
    res = enrich_entities.resolve_entity(entity, client=None)
    assert res["updates"]["lei"] == "ABC123"
    assert res["updates"]["siren"] == "552075020"


def test_resolve_entity_conservative_no_match(monkeypatch):
    # GLEIF renvoie une entreprise homonyme non pertinente -> on n'écrit rien.
    monkeypatch.setattr(gleif, "search_lei",
                        lambda name, country=None, client=None: [{"lei": "ZZZ", "legal_name": "Totally Different Corp", "country": "US"}])
    monkeypatch.setattr(gleif, "direct_parent", lambda lei, client=None: None)
    monkeypatch.setattr(sirene, "search_siren", lambda name, client=None: [])

    entity = {"legal_name": "Bottega Veneta Srl", "country": "IT", "lei": None, "siren": None}
    res = enrich_entities.resolve_entity(entity, client=None)
    assert "lei" not in res["updates"]
    assert any("non résolu" in n for n in res["notes"])


def test_resolve_entity_skips_when_already_set(monkeypatch):
    called = {"gleif": False}
    monkeypatch.setattr(gleif, "search_lei",
                        lambda *a, **k: called.__setitem__("gleif", True) or [])
    monkeypatch.setattr(sirene, "search_siren", lambda *a, **k: [])
    entity = {"legal_name": "Dior", "country": "FR", "lei": "EXISTING", "siren": "123"}
    res = enrich_entities.resolve_entity(entity, client=None)
    assert res["updates"] == {}
    assert called["gleif"] is False
