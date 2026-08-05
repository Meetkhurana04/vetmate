from pydantic import BaseModel, Field
from typing import List

class CreateDoctorProfileRequest(BaseModel):
    specialization: str = Field(
        min_length=2,
        max_length=100
    )
    experience_years: int = Field(
        ge=0
    )
    consultation_fee: float = Field(
        ge=0
    )
    

class Shift(BaseModel):
    start: str
    end: str


class WorkingDay(BaseModel):
    enabled: bool
    shifts: List[Shift] = []

class CreateScheduleRequest(BaseModel):
    slot_duration: int = Field(
        default=20,
        ge=5,
        le=60
    )

    monday: WorkingDay
    tuesday: WorkingDay
    wednesday: WorkingDay
    thursday: WorkingDay
    friday: WorkingDay
    saturday: WorkingDay
    sunday: WorkingDay