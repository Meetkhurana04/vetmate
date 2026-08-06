import math
from datetime import datetime, date
from fastapi import HTTPException, status
from app.repositories.clinic_repository import clinic_repository
from app.repositories.doctor_repository import doctor_schedule_repository, doctor_repository
from app.repositories.appointment_repository import appointment_repository
from app.services.slot_service import generate_slots

def haversine(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    # Haversine formula to calculate distance between two coordinates in km
    R = 6371.0
    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)
    a = math.sin(dlat / 2)**2 + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(dlon / 2)**2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return round(R * c, 1)

def format_12h(time_str: str) -> str:
    t = datetime.strptime(time_str, "%H:%M")
    return t.strftime("%I:%M %p")

class ClinicService:
    def create_clinic(self, current_user, data: dict):
        if current_user.get("role") != "DOCTOR":
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only doctors can create clinics"
            )

        # Set doctor info
        data["doctor_id"] = str(current_user["_id"])
        data["doctorName"] = f"Dr. {current_user.get('name', 'Doctor')}"
        if "rating" not in data:
            data["rating"] = 4.5
        if "isOpen" not in data:
            data["isOpen"] = True
        if "image" not in data:
            data["image"] = "assets/images/happy_paws.png"

        clinic_id = clinic_repository.create_clinic(data)
        
        # Ensure doctor has a default schedule initialized
        schedule = doctor_schedule_repository.find_by_doctor_id(str(current_user["_id"]))
        if not schedule:
            default_schedule = {
                "doctor_id": str(current_user["_id"]),
                "slot_duration": 20,
                "working_days": {
                    "monday": {"enabled": True, "shifts": [{"start": "09:00", "end": "13:00"}, {"start": "14:00", "end": "18:00"}]},
                    "tuesday": {"enabled": True, "shifts": [{"start": "09:00", "end": "13:00"}, {"start": "14:00", "end": "18:00"}]},
                    "wednesday": {"enabled": True, "shifts": [{"start": "09:00", "end": "13:00"}, {"start": "14:00", "end": "18:00"}]},
                    "thursday": {"enabled": True, "shifts": [{"start": "09:00", "end": "13:00"}, {"start": "14:00", "end": "18:00"}]},
                    "friday": {"enabled": True, "shifts": [{"start": "09:00", "end": "13:00"}, {"start": "14:00", "end": "18:00"}]},
                    "saturday": {"enabled": True, "shifts": [{"start": "09:00", "end": "13:00"}, {"start": "14:00", "end": "18:00"}]},
                    "sunday": {"enabled": False, "shifts": []}
                }
            }
            doctor_schedule_repository.create_schedule(default_schedule)

        res = clinic_repository.find_by_id(data.get("id") or str(clinic_id))
        if res and "_id" in res:
            res["_id"] = str(res["_id"])
        return res

    def get_clinics(self, lat: float = None, lng: float = None, leave_date: str = None):
        from app.config.database import db

        # Doctors on leave for the target date (default: today) are hidden from search.
        if leave_date is None:
            leave_date = date.today().isoformat()
        on_leave_doctor_ids = set()
        try:
            for doc in db.users.find({"role": "DOCTOR", "leaves": leave_date}, {"_id": 1}):
                on_leave_doctor_ids.add(str(doc["_id"]))
        except Exception:
            pass

        clinics = clinic_repository.find_all()
        clinics = [
            c for c in clinics
            if c.get("doctor_id") not in on_leave_doctor_ids
        ]
        for clinic in clinics:
            if "_id" in clinic:
                clinic["_id"] = str(clinic["_id"])
        if lat is not None and lng is not None:
            valid_clinics = []
            for clinic in clinics:
                c_lat = clinic.get("latitude")
                c_lng = clinic.get("longitude")
                if c_lat is not None and c_lng is not None:
                    try:
                        dist = haversine(float(lat), float(lng), float(c_lat), float(c_lng))
                        clinic["distance"] = dist
                        valid_clinics.append(clinic)
                    except (ValueError, TypeError):
                        clinic["distance"] = 9999.0
                        valid_clinics.append(clinic)
                else:
                    clinic["distance"] = 9999.0
                    valid_clinics.append(clinic)
            valid_clinics.sort(key=lambda x: x.get("distance", 9999.0))
            return valid_clinics
        return clinics

    def get_clinic_slots(self, clinic_id: str, appointment_date_str: str = None):
        clinic = clinic_repository.find_by_id(clinic_id)
        if not clinic:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Clinic not found"
            )

        doctor_id = clinic.get("doctor_id")
        if not doctor_id:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Doctor associated with this clinic not found"
            )

        # Determine target date
        if appointment_date_str:
            target_date = datetime.strptime(appointment_date_str, "%Y-%m-%d").date()
        else:
            target_date = date.today()

        # Check if doctor is on leave on target_date
        from app.config.database import db
        from bson import ObjectId
        try:
            doctor_doc = db.users.find_one({"_id": ObjectId(doctor_id)})
            if doctor_doc:
                target_date_str = target_date.strftime("%Y-%m-%d")
                if target_date_str in doctor_doc.get("leaves", []):
                    return []
        except Exception:
            pass

        # Get schedule
        schedule = doctor_schedule_repository.find_by_doctor_id(doctor_id)
        if not schedule:
            schedule = {
                "doctor_id": doctor_id,
                "slot_duration": 20,
                "working_days": {
                    "monday": {"enabled": True, "shifts": [{"start": "09:00", "end": "13:00"}, {"start": "14:00", "end": "18:00"}]},
                    "tuesday": {"enabled": True, "shifts": [{"start": "09:00", "end": "13:00"}, {"start": "14:00", "end": "18:00"}]},
                    "wednesday": {"enabled": True, "shifts": [{"start": "09:00", "end": "13:00"}, {"start": "14:00", "end": "18:00"}]},
                    "thursday": {"enabled": True, "shifts": [{"start": "09:00", "end": "13:00"}, {"start": "14:00", "end": "18:00"}]},
                    "friday": {"enabled": True, "shifts": [{"start": "09:00", "end": "13:00"}, {"start": "14:00", "end": "18:00"}]},
                    "saturday": {"enabled": True, "shifts": [{"start": "09:00", "end": "13:00"}, {"start": "14:00", "end": "18:00"}]},
                    "sunday": {"enabled": False, "shifts": []}
                }
            }
            doctor_schedule_repository.create_schedule(schedule)

        weekday = target_date.strftime("%A").lower()
        working_day = schedule["working_days"].get(weekday)

        if not working_day or not working_day["enabled"]:
            return []

        slots_list = []
        duration = schedule["slot_duration"]
        for shift in working_day["shifts"]:
            slots_list.extend(generate_slots(shift["start"], shift["end"], duration))

        # Get booked slots for this doctor on target_date
        booked = appointment_repository.get_booked_slots(doctor_id, target_date)
        booked_times = {slot["start_time"] for slot in booked}

        now = datetime.now()
        is_today = target_date == now.date()

        # Convert to frontend slot format
        frontend_slots = []
        for i, s in enumerate(slots_list):
            start_24h = s["start"]
            
            if is_today:
                slot_time = datetime.strptime(start_24h, "%H:%M").time()
                if slot_time <= now.time():
                    continue

            is_booked = start_24h in booked_times
            
            frontend_slots.append({
                "id": f"slot_{start_24h}",
                "time": format_12h(start_24h),
                "isBooked": is_booked,
                "isAvailable": not is_booked,
                "bookedBy": None
            })

        return frontend_slots

clinic_service = ClinicService()
