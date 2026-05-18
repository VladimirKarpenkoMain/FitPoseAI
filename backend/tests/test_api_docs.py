from fastapi.testclient import TestClient

from app.main import create_app


def test_api_docs_are_disabled_when_not_explicitly_enabled():
    client = TestClient(create_app(enable_api_docs=False))

    assert client.get("/docs").status_code == 404
    assert client.get("/redoc").status_code == 404
    assert client.get("/openapi.json").status_code == 404


def test_api_docs_can_be_enabled_for_local_development():
    client = TestClient(create_app(enable_api_docs=True))

    assert client.get("/docs").status_code == 200
    assert client.get("/redoc").status_code == 200
    assert client.get("/openapi.json").status_code == 200
