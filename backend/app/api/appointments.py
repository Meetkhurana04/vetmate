from fastapi import APIRouter,Depends

from app.schemas.appointment_schema import (
    AvailableSlotRequest,BookAppointmentRequest
)

from app.services.appointment_service import (
    appointment_service
)
from app.dependencies.auth import (
    get_current_user
)

router = APIRouter(
    prefix="/appointments",
    tags=["Appointments"]
)


@router.post(
    "/available-slots"
)
def available_slots(
    data: AvailableSlotRequest
):

    return appointment_service.get_available_slots(

        doctor_id=data.doctor_id,

        appointment_date=data.appointment_date

    )

@router.post("/book")
def book(data:BookAppointmentRequest,current_user=Depends(get_current_user)):
    return appointment_service.book_appointment(
            current_user,
            data
        )

@router.get("/my")
def my_appointments(current_user=Depends(get_current_user)):
    return appointment_service.my_appointments(
        current_user
    )

@router.post("/{appointment_id}/cancel")
def cancel(appointment_id: str, current_user=Depends(get_current_user)):
    return appointment_service.cancel_appointment(
        current_user,
        appointment_id
    )