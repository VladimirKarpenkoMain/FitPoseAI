from datetime import datetime, UTC

from sqlalchemy import JSON, Column, Integer, String, DateTime, ForeignKey
from sqlalchemy.orm import relationship

from app.database import Base


class WorkoutSession(Base):
    __tablename__ = "workout_sessions"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    exercise_type = Column(String, nullable=False)
    rep_count = Column(Integer, nullable=False)
    date = Column(DateTime, default=lambda: datetime.now(UTC))
    average_quality_score = Column(Integer, nullable=True)
    analysis = Column(JSON, nullable=True)

    user = relationship("User", back_populates="workouts")
