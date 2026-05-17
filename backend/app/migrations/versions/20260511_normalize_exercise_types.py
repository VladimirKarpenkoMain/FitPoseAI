"""Normalize exercise types

Revision ID: 20260511_normalize_exercise_type
Revises: 20260505_workout_analysis
Create Date: 2026-05-11 18:00:00.000000
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "20260511_normalize_exercise_type"
down_revision: Union[str, None] = "20260505_workout_analysis"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


DEFAULT_EXERCISE_TYPES = {
    "squat": "Squat",
    "pushup": "Push-up",
    "jumping_jack": "Jumping Jack",
    "plank": "Plank",
    "shoulder_press": "Dumbbell Shoulder Press",
}


def _display_name(code: str) -> str:
    return DEFAULT_EXERCISE_TYPES.get(code, code.replace("_", " ").title())


def upgrade() -> None:
    op.create_table(
        "exercise_types",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("code", sa.String(), nullable=False),
        sa.Column("name", sa.String(), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_exercise_types_id"), "exercise_types", ["id"], unique=False)
    op.create_index(op.f("ix_exercise_types_code"), "exercise_types", ["code"], unique=True)

    connection = op.get_bind()
    existing_codes = [
        row[0]
        for row in connection.execute(
            sa.text(
                "SELECT DISTINCT exercise_type "
                "FROM workout_sessions "
                "WHERE exercise_type IS NOT NULL"
            )
        )
    ]
    codes = list(DEFAULT_EXERCISE_TYPES)
    codes.extend(code for code in existing_codes if code not in DEFAULT_EXERCISE_TYPES)

    for code in codes:
        connection.execute(
            sa.text(
                "INSERT INTO exercise_types (code, name) "
                "SELECT :code, :name "
                "WHERE NOT EXISTS ("
                "SELECT 1 FROM exercise_types WHERE code = :code"
                ")"
            ),
            {"code": code, "name": _display_name(code)},
        )

    op.add_column(
        "workout_sessions",
        sa.Column("exercise_type_id", sa.Integer(), nullable=True),
    )
    connection.execute(
        sa.text(
            "UPDATE workout_sessions "
            "SET exercise_type_id = ("
            "SELECT id FROM exercise_types "
            "WHERE exercise_types.code = workout_sessions.exercise_type"
            ")"
        )
    )

    with op.batch_alter_table("workout_sessions") as batch_op:
        batch_op.alter_column(
            "exercise_type_id",
            existing_type=sa.Integer(),
            nullable=False,
        )
        batch_op.create_foreign_key(
            "fk_workout_sessions_exercise_type_id_exercise_types",
            "exercise_types",
            ["exercise_type_id"],
            ["id"],
        )
        batch_op.drop_column("exercise_type")


def downgrade() -> None:
    connection = op.get_bind()

    op.add_column(
        "workout_sessions",
        sa.Column("exercise_type", sa.String(), nullable=True),
    )
    connection.execute(
        sa.text(
            "UPDATE workout_sessions "
            "SET exercise_type = ("
            "SELECT code FROM exercise_types "
            "WHERE exercise_types.id = workout_sessions.exercise_type_id"
            ")"
        )
    )

    with op.batch_alter_table("workout_sessions") as batch_op:
        batch_op.alter_column(
            "exercise_type",
            existing_type=sa.String(),
            nullable=False,
        )
        batch_op.drop_constraint(
            "fk_workout_sessions_exercise_type_id_exercise_types",
            type_="foreignkey",
        )
        batch_op.drop_column("exercise_type_id")

    op.drop_index(op.f("ix_exercise_types_code"), table_name="exercise_types")
    op.drop_index(op.f("ix_exercise_types_id"), table_name="exercise_types")
    op.drop_table("exercise_types")
