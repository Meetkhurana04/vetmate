from fastapi import FastAPI

from app.config.settings import settings
from app.api.auth import router as auth_router
from app.api.doctors import (router as doctor_router)
from app.api.appointments import (router as appointment_router)
from app.api.clinics import router as clinics_router

app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    debug=settings.DEBUG,
)


@app.get("/", tags=["Health"])
def health_check():
    return {
        "status": "running",
        "application": settings.APP_NAME,
        "version": settings.APP_VERSION,
    }

app.include_router(doctor_router)
app.include_router(appointment_router)
app.include_router(auth_router)
app.include_router(clinics_router)