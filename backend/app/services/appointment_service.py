from datetime import datetime, timedelta

from app.repositories.appointment_repository import appointment_repository

from app.repositories.doctor_repository import doctor_schedule_repository
from app.services.slot_service import generate_slots

from fastapi import HTTPException, status


class AppointmentService:
    def get_available_slots(self,doctor_id,appointment_date):
        schedule = doctor_schedule_repository.find_by_doctor_id(
            doctor_id
        )

        if not schedule:
            return []

        weekday = appointment_date.strftime(
            "%A"
        ).lower()

        working_day = schedule[
            "working_days"
        ][weekday]

        if not working_day["enabled"]:
            return []

        slots = []

        duration = schedule[
            "slot_duration"
        ]

        for shift in working_day["shifts"]:
            slots.extend(
                generate_slots(
                    shift["start"],
                    shift["end"],
                    duration
                )
            )

        booked = appointment_repository.get_booked_slots(
            doctor_id,
            appointment_date

        )

        booked_times = {
            slot["start_time"]
            for slot in booked
        }

        available = [
            slot
            for slot in slots
            if slot["start"] not in booked_times
        ]

        return available

    def book_appointment(self,current_user,data):

        schedule = doctor_schedule_repository.find_by_doctor_id(
            data.doctor_id
        )

        if schedule is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Doctor schedule not found",
            )

        weekday = data.appointment_date.strftime(
            "%A"
        ).lower()

        working_day = schedule["working_days"].get(
            weekday
        )

        if (
            working_day is None
            or not working_day["enabled"]
        ):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Doctor is not available on this day",
            )

        all_slots = []

        duration = schedule["slot_duration"]

        for shift in working_day["shifts"]:

            generated = generate_slots(
                start_time=shift["start"],
                end_time=shift["end"],
                duration=duration,
            )

            all_slots.extend(generated)

        selected_slot = None

        for slot in all_slots:

            if slot["start"] == data.start_time:
                selected_slot = slot
                break

        if selected_slot is None:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid appointment slot",
            )


        existing = appointment_repository.find_slot(
            doctor_id=data.doctor_id,
            appointment_date=data.appointment_date,
            start_time=data.start_time,
        )

        if existing:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Slot already booked",
            )

        start = datetime.strptime(
            data.start_time,
            "%H:%M",
        )

        end = start + timedelta(
            minutes=duration
        )

        appointment = {

            "doctor_id": data.doctor_id,

            "patient_id": str(
                current_user["_id"]
            ),

            "appointment_date": str(
                data.appointment_date
            ),

            "start_time": data.start_time,

            "end_time": end.strftime(
                "%H:%M"
            ),

            "status": "BOOKED",
        }


        appointment_id = (
            appointment_repository.create(
                appointment
            )
        )

        return {
            "message": "Appointment booked successfully",
            "appointment_id": str(
                appointment_id
            ),
        }

    def my_appointments(self,current_user):
        appointments = (
            appointment_repository.find_by_patient(
                str(current_user["_id"])
            )
        )

        response = []
        for appointment in appointments:
            response.append({
                "appointment_id": str(
                    appointment["_id"]
                ),

                "doctor_id":
                    appointment["doctor_id"],

                "appointment_date":
                    appointment["appointment_date"],

                "start_time":
                    appointment["start_time"],

                "end_time":
                    appointment["end_time"],

                "status":
                    appointment["status"]

            })

        return response


appointment_service = AppointmentService()