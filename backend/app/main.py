from fastapi import FastAPI

from app.routes import auth, workouts

app = FastAPI(
    title="Fitness AI API",
    description="Backend API for AI Fitness MVP",
    version="1.0.0"
)

# Include routers
app.include_router(auth.router)
app.include_router(workouts.router)


@app.get("/")
def root():
    """Health check endpoint."""
    return {"status": "ok", "message": "Fitness AI API is running"}
