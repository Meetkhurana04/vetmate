from pydantic import BaseModel, EmailStr, Field
from typing import Literal, Optional

class RegisterRequest(BaseModel):
    name: str = Field(min_length=3, max_length=100)

    email: EmailStr

    phone: str = Field(min_length=10, max_length=10)

    password: str = Field(min_length=8)

    role: Literal["PATIENT", "DOCTOR"]

    latitude: Optional[float] = None
    longitude: Optional[float] = None

class RegisterResponse(BaseModel):
    message: str
    user_id: str



class LoginRequest(BaseModel):
    email: EmailStr
    password: str
    role: Optional[str] = None