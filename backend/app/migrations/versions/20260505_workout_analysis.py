"""Add workout analysis metadata

Revision ID: 20260505_workout_analysis
Revises: 9712a0a8cc17
Create Date: 2026-05-05 21:00:00.000000
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "20260505_workout_analysis"
down_revision: Union[str, None] = "9712a0a8cc17"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "workout_sessions",
        sa.Column("average_quality_score", sa.Integer(), nullable=True),
    )
    op.add_column(
        "workout_sessions",
        sa.Column("analysis", sa.JSON(), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("workout_sessions", "analysis")
    op.drop_column("workout_sessions", "average_quality_score")
