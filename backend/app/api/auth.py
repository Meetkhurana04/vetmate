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