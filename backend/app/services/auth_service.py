from fastapi import HTTPException, status

from app.repositories.user_repository import user_repository
from app.utils.password import hash_password
from fastapi import status
from fastapi.responses import JSONResponse
from app.utils.jwt import create_access_token
from app.utils.password import verify_password

class AuthService:
    def register(self, data):
        existing_user = user_repository.find_by_email(
            data.email
        )

        if existing_user:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Email already registered"
            )

        user = {
            "name": data.name,
            "email": data.email,
            "password": hash_password(
                data.password
            ),
            "role": data.role
        }

        user_id = user_repository.create_user(
            user
        )

        return JSONResponse(
            status_code=status.HTTP_201_CREATED,
            content={
                "message": "Registration Successful",
                "user_id": str(user_id),
            }
        )

    def login(self, data):

        user = user_repository.find_by_email(data.email)

        if not user:

            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )

        if not verify_password(
            data.password,
            user["password"]
        ):

            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid credentials"
            )

        token = create_access_token({

            "user_id": str(user["_id"]),

            "role": user["role"]

        })

        return {

            "access_token": token,

            "token_type": "bearer"

        }


auth_service = AuthService()