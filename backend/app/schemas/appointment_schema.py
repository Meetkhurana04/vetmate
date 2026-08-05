from datetime import date
from pydantic import BaseModel, Field


class AvailableSlotRequest(BaseModel):
    doctor_id: str
    appointment_date: date


class BookAppointmentRequest(BaseModel):
    doctor_id: str
    appointment_date: date
    start_time: str = Field(pattern=r"^\d{2}:\d{2}$")