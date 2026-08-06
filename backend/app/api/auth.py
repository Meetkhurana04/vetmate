from fastapi import APIRouter, status

from app.schemas.auth_schema import (
    RegisterRequest,
    LoginRequest,
)

from app.services.auth_service import auth_service

router = APIRouter(
    prefix="/auth",
    tags=["Authentication"],
)


@router.post(
    "/register",
    status_code=status.HTTP_201_CREATED,
)
def register(data: RegisterRequest):
    return auth_service.register(data)


@router.post(
    "/login",
    status_code=status.HTTP_200_OK,
)
def login(data: LoginRequest):
    return auth_service.login(data)


from app.utils.jwt import decode_access_token, create_access_token
from fastapi import HTTPException

@router.post(
    "/refresh",
    status_code=status.HTTP_200_OK,
)
def refresh(payload: dict):
    refresh_token = payload.get("refreshToken") or payload.get("refresh_token")
    if not refresh_token:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Refresh token is required"
        )
    
    decoded = decode_access_token(refresh_token)
    if not decoded:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired refresh token"
        )
        
    new_token = create_access_token({
        "user_id": decoded["user_id"],
        "role": decoded["role"]
    })
    return {
        "accessToken": new_token,
        "refreshToken": refresh_token,
        "access_token": new_token,
        "refresh_token": refresh_token
    }

from fastapi import Depends
from app.dependencies.auth import get_current_user
from pydantic import BaseModel
from typing import Optional

class UpdateProfileRequest(BaseModel):
    name: Optional[str] = None
    phone: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None

class DoctorLeaveRequest(BaseModel):
    date: str
    action: str = "TAKE" # "TAKE" or "CANCEL"

@router.put("/profile")
def update_profile(data: UpdateProfileRequest, current_user=Depends(get_current_user)):
    return auth_service.update_profile(current_user, data)

@router.post("/doctors/leave")
def manage_leave(data: DoctorLeaveRequest, current_user=Depends(get_current_user)):
    if current_user.get("role") != "DOCTOR":
        raise HTTPException(
            status_code=403,
            detail="Only doctors can manage leave"
        )
    return auth_service.manage_leave(current_user, data)