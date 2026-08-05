from fastapi import APIRouter
from fastapi import Depends

from app.dependencies.auth import (
    get_current_user
)

from app.schemas.doctor_schema import (
    CreateDoctorProfileRequest
)

from app.services.doctor_service import (
    doctor_service
)

router = APIRouter(
    prefix="/doctors",
    tags=["Doctors"]
)


@router.post("/profile")
def create_profile(
    data: CreateDoctorProfileRequest,
    current_user=Depends(
        get_current_user
    )):

    return doctor_service.create_profile(
        current_user,
        data
    )