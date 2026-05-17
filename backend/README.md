# FitPose AI Backend

FastAPI backend for the FitPose AI MVP application.

**Requires Python 3.12+**

## Setup

### 1. Create Virtual Environment

```bash
cd backend
python -m venv venv

# Windows
venv\Scripts\activate

# Linux/Mac
source venv/bin/activate
```

### 2. Install Dependencies

```bash
pip install -r requirements.txt
```

### 3. Configure PostgreSQL

Create a database named `fitness_db` in PostgreSQL:

```sql
CREATE DATABASE fitness_db;
```

Create `.env` file in `backend/app/`:

```env
DATABASE_URL=postgresql://postgres:your_password@localhost:5432/fitness_db
SECRET_KEY=your-super-secret-key-change-this
```

### 4. Run Migrations

```bash
cd app
alembic revision --autogenerate -m "Initial migration"
alembic upgrade head
```

### 5. Run the Server

```bash
cd backend
uvicorn app.main:app --reload
```

The API will be available at: http://localhost:8000

## Migrations (Alembic)

All migration commands should be run from `backend/app/` directory:

```bash
cd backend/app

# Create new migration
alembic revision --autogenerate -m "Description of changes"

# Apply migrations
alembic upgrade head

# Rollback one migration
alembic downgrade -1

# Show current revision
alembic current

# Show migration history
alembic history
```

## Tech Stack

- **Python** 3.12+
- **FastAPI** 0.115+
- **Pydantic** 2.10+
- **SQLAlchemy** 2.0+
- **Alembic** 1.14+
- **PostgreSQL** + psycopg2

## API Endpoints

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/` | Health check | No |
| POST | `/register` | Register new user | No |
| POST | `/login` | Login, get JWT token | No |
| POST | `/workouts` | Save workout session | JWT |
| GET | `/workouts` | List user's workouts | JWT |

## API Documentation

- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## Workout analysis payload

`POST /workouts` now accepts optional fields:

- `average_quality_score`
- `analysis`

The `analysis` JSON stores required view, readiness time, dominant issues, and rep-level analytics.
