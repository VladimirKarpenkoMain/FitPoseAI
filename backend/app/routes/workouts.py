from typing import Annotated

from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.user import User
from app.models.workout import WorkoutSession
from app.schemas.workout import WorkoutCreate, WorkoutResponse
from app.utils.auth import get_current_user
from app.utils.logger import logger

router = APIRouter(prefix="/workouts", tags=["workouts"])


@router.post("", response_model=WorkoutResponse, status_code=status.HTTP_201_CREATED)
def create_workout(
    workout_data: WorkoutCreate,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)]
):
    """Save a new workout session."""
    logger.info(f"Creating workout for user {current_user.email}: {workout_data.exercise_type}, {workout_data.rep_count} reps")
    
    workout = WorkoutSession(
        user_id=current_user.id,
        exercise_type=workout_data.exercise_type,
        rep_count=workout_data.rep_count,
        average_quality_score=workout_data.average_quality_score,
        analysis=workout_data.analysis,
    )
    db.add(workout)
    db.commit()
    db.refresh(workout)
    
    logger.info(f"Workout saved successfully: ID {workout.id}")
    return workout


@router.get("", response_model=list[WorkoutResponse])
def list_workouts(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)]
):
    """List all workouts for the current user."""
    logger.debug(f"Fetching workouts for user {current_user.email}")
    
    workouts = db.query(WorkoutSession).filter(
        WorkoutSession.user_id == current_user.id
    ).order_by(WorkoutSession.date.desc()).all()
    
    logger.info(f"Found {len(workouts)} workouts for user {current_user.email}")
    return workouts
