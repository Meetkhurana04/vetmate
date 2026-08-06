from datetime import datetime, timedelta

from pymongo.errors import DuplicateKeyError

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
        # Resolve doctor_id, date and start_time from clinicId and other fields
        doctor_id = data.doctor_id
        apt_date = data.appointment_date or data.date
        start_time_str = data.start_time or data.time

        if not apt_date:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Appointment date is required",
            )
        if not start_time_str:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Start time is required",
            )

        # Map clinicId to doctor_id and get metadata
        clinic_name = "General Clinic"
        doctor_name = "Doctor"
        clinic_image = "assets/images/happy_paws.png"

        if data.clinicId:
            from app.repositories.clinic_repository import clinic_repository
            clinic = clinic_repository.find_by_id(data.clinicId)
            if clinic:
                doctor_id = clinic.get("doctor_id")
                clinic_name = clinic.get("name", clinic_name)
                doctor_name = clinic.get("doctorName", doctor_name)
                clinic_image = clinic.get("image", clinic_image)
            else:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Clinic not found",
                )

        if not doctor_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Doctor ID is required",
            )

        # Parse AM/PM format to 24-hour if necessary
        if "AM" in start_time_str or "PM" in start_time_str:
            try:
                t = datetime.strptime(start_time_str.strip(), "%I:%M %p")
                start_time_str = t.strftime("%H:%M")
            except ValueError:
                pass

        schedule = doctor_schedule_repository.find_by_doctor_id(
            doctor_id
        )

        if schedule is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Doctor schedule not found",
            )

        weekday = apt_date.strftime(
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

            if slot["start"] == start_time_str:
                selected_slot = slot
                break

        if selected_slot is None:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid appointment slot",
            )


        existing = appointment_repository.find_slot(
            doctor_id=doctor_id,
            appointment_date=apt_date,
            start_time=start_time_str,
        )

        if existing:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Slot already booked",
            )

        start = datetime.strptime(
            start_time_str,
            "%H:%M",
        )

        end = start + timedelta(
            minutes=duration
        )

        appointment = {
            "doctor_id": doctor_id,
            "patient_id": str(
                current_user["_id"]
            ),
            "appointment_date": str(
                apt_date
            ),
            "start_time": start_time_str,
            "end_time": end.strftime(
                "%H:%M"
            ),
            "status": "BOOKED",
            "clinic_id": data.clinicId or "",
            "clinic_name": clinic_name,
            "doctor_name": doctor_name,
            "clinic_image": clinic_image,
            "slot_id": data.slotId or f"slot_{start_time_str}",
        }


        try:
            appointment_id = (
                appointment_repository.create(
                    appointment
                )
            )
        except DuplicateKeyError:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Slot already booked",
            )

        return {
            "message": "Appointment booked successfully",
            "appointment_id": str(
                appointment_id
            ),
        }

    def my_appointments(self,current_user):
        from bson import ObjectId
        from app.config.database import db

        if current_user.get("role") == "DOCTOR":
            appointments = (
                appointment_repository.find_by_doctor(
                    str(current_user["_id"])
                )
            )
        else:
            appointments = (
                appointment_repository.find_by_patient(
                    str(current_user["_id"])
                )
            )

        def format_12h(time_str: str) -> str:
            try:
                t = datetime.strptime(time_str, "%H:%M")
                return t.strftime("%I:%M %p")
            except Exception:
                return time_str

        response = []
        for appointment in appointments:
            start_time = appointment.get("start_time")
            patient_name = "Patient"
            if current_user.get("role") == "DOCTOR":
                try:
                    patient = db.users.find_one({"_id": ObjectId(appointment.get("patient_id"))})
                    if patient:
                        patient_name = patient.get("name", "Patient")
                except Exception:
                    pass

            response.append({
                "appointment_id": str(
                    appointment["_id"]
                ),

                "doctor_id":
                    appointment.get("doctor_id"),

                "appointment_date":
                    appointment.get("appointment_date"),

                "start_time":
                    start_time,

                "end_time":
                    appointment.get("end_time"),

                "status":
                    appointment.get("status"),

                "clinicId": appointment.get("clinic_id", ""),
                "clinicName": appointment.get("clinic_name", "Clinic"),
                "doctorName": f"Patient: {patient_name}" if current_user.get("role") == "DOCTOR" else appointment.get("doctor_name", "Doctor"),
                "clinicImage": appointment.get("clinic_image", "assets/images/happy_paws.png"),
                "slotId": appointment.get("slot_id", ""),
                "slotTime": format_12h(start_time) if start_time else ""
            })

        return response

    def cancel_appointment(self, current_user, appointment_id: str):
        from bson import ObjectId
        from datetime import datetime
        from fastapi import HTTPException, status
        from app.config.database import db
        from app.constants.collections import NOTIFICATIONS_COLLECTION
        
        try:
            obj_id = ObjectId(appointment_id)
        except Exception:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid appointment ID format"
            )
            
        appointment = db.appointments.find_one({"_id": obj_id})
        if not appointment:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Appointment not found"
            )
            
        if appointment.get("patient_id") != str(current_user["_id"]) and appointment.get("doctor_id") != str(current_user["_id"]):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Not authorized to cancel this appointment"
            )

        already_cancelled = appointment.get("status") == "CANCELLED"
        appointment_repository.cancel(appointment_id)

        if not already_cancelled:
            canceller_is_doctor = str(current_user["_id"]) == appointment.get("doctor_id")
            if canceller_is_doctor:
                recipient_id = appointment.get("patient_id")
                other_name = "Patient"
                message = (f"Your appointment with {appointment.get('doctor_name', 'Doctor')} on "
                           f"{appointment.get('appointment_date', '')} at {appointment.get('start_time', '')} "
                           f"was cancelled by the doctor.")
            else:
                recipient_id = appointment.get("doctor_id")
                other_name = "Doctor"
                message = (f"Your appointment with {appointment.get('doctor_name', 'Doctor')} on "
                           f"{appointment.get('appointment_date', '')} at {appointment.get('start_time', '')} "
                           f"was cancelled by the patient.")

            if recipient_id:
                db[NOTIFICATIONS_COLLECTION].insert_one({
                    "user_id": recipient_id,
                    "type": "APPOINTMENT_CANCELLED",
                    "title": "Appointment cancelled",
                    "message": message,
                    "appointment_date": appointment.get("appointment_date", ""),
                    "doctor_name": appointment.get("doctor_name", "Doctor"),
                    "read": False,
                    "created_at": datetime.now()
                })

        return {"message": "Appointment cancelled successfully"}


appointment_service = AppointmentService()