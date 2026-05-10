from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.database import Base, get_db
from app.main import app


engine = create_engine(
    "sqlite://",
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base.metadata.create_all(bind=engine)


def override_get_db():
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()


app.dependency_overrides[get_db] = override_get_db
client = TestClient(app)


def test_login_returns_refresh_token_and_refresh_issues_new_access_token():
    email = "refresh@example.com"
    password = "secret123"

    register_response = client.post(
        "/register",
        json={"email": email, "password": password},
    )
    assert register_response.status_code == 201

    login_response = client.post(
        "/login",
        data={"username": email, "password": password},
    )
    assert login_response.status_code == 200
    login_payload = login_response.json()
    assert login_payload["access_token"]
    assert login_payload["refresh_token"]

    refresh_response = client.post(
        "/refresh",
        json={"refresh_token": login_payload["refresh_token"]},
    )

    assert refresh_response.status_code == 200
    refresh_payload = refresh_response.json()
    assert refresh_payload["access_token"]
    assert refresh_payload["refresh_token"] == login_payload["refresh_token"]


def test_refresh_rejects_access_token():
    email = "refresh-access@example.com"
    password = "secret123"

    client.post("/register", json={"email": email, "password": password})
    login_response = client.post(
        "/login",
        data={"username": email, "password": password},
    )
    access_token = login_response.json()["access_token"]

    refresh_response = client.post(
        "/refresh",
        json={"refresh_token": access_token},
    )

    assert refresh_response.status_code == 401
