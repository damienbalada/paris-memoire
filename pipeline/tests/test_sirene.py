import httpx

from paris_memoire.connectors.sirene import parse_result, search_siren


def test_parse_result_prefers_nom_complet():
    assert parse_result({"siren": "552032534", "nom_complet": "DANONE",
                         "nom_raison_sociale": "DANONE SA"})["nom"] == "DANONE"
    assert parse_result({"siren": "1", "nom_raison_sociale": "X"})["nom"] == "X"


def test_search_skips_short_queries_without_calling_api():
    # Une requete < 3 caracteres (ex. LU) renverrait 400 : on n'appelle meme
    # pas l'API et on renvoie [] - sinon tout le lot planterait.
    def _boom(*a, **k):
        raise AssertionError("l'API ne doit pas etre appelee pour une requete courte")

    client = httpx.Client()
    client.get = _boom  # type: ignore[assignment]
    assert search_siren("LU", client=client) == []
    assert search_siren(" ", client=client) == []


def test_search_returns_empty_on_http_error():
    class Resp:
        status_code = 400
        def json(self):
            return {}

    client = httpx.Client()
    client.get = lambda *a, **k: Resp()  # type: ignore[assignment]
    assert search_siren("Nom Valide", client=client) == []


def test_search_parses_results_on_success():
    class Resp:
        status_code = 200
        def json(self):
            return {"results": [{"siren": "552032534", "nom_complet": "DANONE"}]}

    client = httpx.Client()
    client.get = lambda *a, **k: Resp()  # type: ignore[assignment]
    out = search_siren("Danone", client=client)
    assert out == [{"siren": "552032534", "nom": "DANONE"}]
