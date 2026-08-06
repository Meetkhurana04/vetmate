import datetime
from pydantic import BaseModel, Field
from typing import Optional

class AvailableSlotRequest(BaseModel):
    doctor_id: str
    appointment_date: datetime.date

class BookAppointmentRequest(BaseModel):
    doctor_id: Optional[str] = None
    appointment_date: Optional[datetime.date] = None
    start_time: Optional[str] = None
    
    clinicId: Optional[str] = None
    slotId: Optional[str] = None
    date: Optional[datetime.date] = None
    time: Optional[str] = None