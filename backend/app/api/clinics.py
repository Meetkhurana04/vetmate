from fastapi import APIRouter, Depends, Query, status
from typing import Optional
from app.dependencies.auth import get_current_user
from app.services.clinic_service import clinic_service

router = APIRouter(
    prefix="/clinics",
    tags=["Clinics"]
)

@router.post("", status_code=status.HTTP_201_CREATED)
def create_clinic(data: dict, current_user = Depends(get_current_user)):
    return clinic_service.create_clinic(current_user, data)

@router.get("")
def get_clinics(
    lat: Optional[float] = Query(None),
    lng: Optional[float] = Query(None),
    date: Optional[str] = Query(None)
):
    return clinic_service.get_clinics(lat, lng, leave_date=date)

@router.get("/{clinic_id}/slots")
def get_clinic_slots(
    clinic_id: str,
    date: Optional[str] = Query(None)
):
    return clinic_service.get_clinic_slots(clinic_id, date)
