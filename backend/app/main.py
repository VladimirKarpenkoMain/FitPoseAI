from fastapi import FastAPI

from app.routes import auth, workouts

app = FastAPI(
    title="FitPose AI API",
    description="Backend API for FitPose AI MVP",
    version="1.0.0"
)

# Include routers
app.include_router(auth.router)
app.include_router(workouts.router)


@app.get("/")
def root():
    """Health check endpoint."""
    return {"status": "ok", "message": "FitPose AI API is running"}
