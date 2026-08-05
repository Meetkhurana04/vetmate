from pydantic import BaseModel, EmailStr, Field
from typing import Literal


class RegisterRequest(BaseModel):
    name: str = Field(min_length=3, max_length=100)

    email: EmailStr

    phone: str = Field(min_length=10, max_length=10)

    password: str = Field(min_length=8)

    role: Literal["PATIENT", "DOCTOR"]

class RegisterResponse(BaseModel):
    message: str
    user_id: str



class LoginRequest(BaseModel):
    email: EmailStr
    password: str