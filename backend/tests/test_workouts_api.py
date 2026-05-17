from datetime import UTC, datetime

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.database import Base, get_db
from app.main import app
from app.models.workout import WorkoutSession
from app.models.exercise_type import ExerciseType
from app.models.user import User
from app.utils.auth import get_current_user


engine = create_engine(
    "sqlite://",
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base.metadata.create_all(bind=engine)

with TestingSessionLocal() as db:
    db.add_all(
        [
            ExerciseType(code="squat", name="Squat"),
            ExerciseType(code="pushup", name="Push-up"),
            ExerciseType(code="jumping_jack", name="Jumping Jack"),
            ExerciseType(code="plank", name="Plank"),
            ExerciseType(code="shoulder_press", name="Dumbbell Shoulder Press"),
        ]
    )
    db.commit()


def override_get_db():
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()


def override_get_current_user():
    return User(id=1, email="planner@example.com", hashed_password="x", created_at=datetime.now(UTC))


app.dependency_overrides[get_db] = override_get_db
app.dependency_overrides[get_current_user] = override_get_current_user
client = TestClient(app)


@pytest.fixture(autouse=True)
def clear_workouts():
    with TestingSessionLocal() as db:
        db.query(WorkoutSession).delete()
        db.commit()


def test_create_and_list_workout_preserves_analysis_payload():
    create_response = client.post(
        "/workouts",
        json={
            "exercise_type": "squat",
            "rep_count": 8,
            "average_quality_score": 74,
            "analysis": {
                "required_view": "side",
                "readiness_time_seconds": 10,
                "dominant_issues": ["depth_too_shallow"],
                "rep_analyses": [
                    {
                        "rep_index": 1,
                        "quality_score": 62,
                        "quality_label": "fair",
                        "issues": ["depth_too_shallow"],
                        "metrics_snapshot": {"min_knee_angle": 108},
                    }
                ],
            },
        },
    )

    assert create_response.status_code == 201
    payload = create_response.json()
    assert payload["average_quality_score"] == 74
    assert payload["analysis"]["required_view"] == "side"
    assert payload["analysis"]["rep_analyses"][0]["quality_score"] == 62

    list_response = client.get("/workouts")
    assert list_response.status_code == 200
    assert list_response.json()[0]["analysis"]["dominant_issues"] == ["depth_too_shallow"]


def test_create_workout_stores_exercise_type_as_foreign_key():
    create_response = client.post(
        "/workouts",
        json={
            "exercise_type": "pushup",
            "rep_count": 12,
        },
    )

    assert create_response.status_code == 201
    assert create_response.json()["exercise_type"] == "pushup"

    with TestingSessionLocal() as db:
        workout = db.query(WorkoutSession).filter(WorkoutSession.rep_count == 12).one()
        exercise_type = db.query(ExerciseType).filter(ExerciseType.code == "pushup").one()
        assert workout.exercise_type_id == exercise_type.id
