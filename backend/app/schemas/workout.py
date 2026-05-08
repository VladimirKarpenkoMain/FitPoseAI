from datetime import datetime
from typing import Any

from pydantic import BaseModel, ConfigDict


class WorkoutCreate(BaseModel):
    exercise_type: str
    rep_count: int
    average_quality_score: int | None = None
    analysis: dict[str, Any] | None = None


class WorkoutResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    user_id: int
    exercise_type: str
    rep_count: int
    date: datetime
    average_quality_score: int | None = None
    analysis: dict[str, Any] | None = None
