from sqlalchemy import Column, Integer, String
from sqlalchemy.orm import relationship

from app.database import Base


class ExerciseType(Base):
    __tablename__ = "exercise_types"

    id = Column(Integer, primary_key=True, index=True)
    code = Column(String, unique=True, index=True, nullable=False)
    name = Column(String, nullable=False)

    workouts = relationship("WorkoutSession", back_populates="exercise_type")
