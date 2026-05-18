from fastapi import FastAPI

from app.config import settings
from app.routes import auth, workouts


def create_app(*, enable_api_docs: bool = settings.ENABLE_API_DOCS) -> FastAPI:
    docs_url = "/docs" if enable_api_docs else None
    redoc_url = "/redoc" if enable_api_docs else None
    openapi_url = "/openapi.json" if enable_api_docs else None

    app = FastAPI(
        title="FitPose AI API",
        description="Backend API for FitPose AI MVP",
        version="1.0.0",
        docs_url=docs_url,
        redoc_url=redoc_url,
        openapi_url=openapi_url,
    )

    app.include_router(auth.router)
    app.include_router(workouts.router)

    @app.get("/")
    def root():
        """Health check endpoint."""
        return {"status": "ok", "message": "FitPose AI API is running"}

    return app


app = create_app()
