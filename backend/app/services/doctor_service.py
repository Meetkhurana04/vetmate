from fastapi import HTTPException
from fastapi import status

from app.repositories.doctor_repository import (
    doctor_repository
)


class DoctorService:

    def create_profile(self,current_user,data):
        if current_user["role"] != "DOCTOR":
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only doctors can create profile"
            )

        existing_profile = (
            doctor_repository.find_by_user_id(
                str(current_user["_id"])
            )
        )

        if existing_profile:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Profile already exists"

            )

        doctor_data = {

            "user_id": str(
                current_user["_id"]
            ),

            "specialization":
                data.specialization,

            "experience_years":
                data.experience_years,

            "consultation_fee":
                data.consultation_fee,

            "is_active": True
        }

        doctor_id = (
            doctor_repository.create_profile(
                doctor_data
            )
        )

        return {
            "message":
                "Doctor profile created",
            "doctor_id":
                str(doctor_id)
        }


doctor_service = DoctorService()