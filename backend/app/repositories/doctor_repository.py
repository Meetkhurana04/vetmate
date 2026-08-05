from app.config.database import db

from app.constants.collections import (
    DOCTORS_COLLECTION, DOCTOR_SCHEDULES_COLLECTION
)

class DoctorRepository:
    def create_profile(self,doctor_data: dict):
        result = db[DOCTORS_COLLECTION].insert_one(
            doctor_data
        )
        return result.inserted_id

    def find_by_user_id(self,user_id: str):
        return db[DOCTORS_COLLECTION].find_one(
            {
                "user_id": user_id
            }
        )

    from app.config.database import db


class DoctorScheduleRepository:
    def find_schedule(self,doctor_id: str):
        return db[DOCTOR_SCHEDULES_COLLECTION].find_one({
            "doctor_id": doctor_id
        })


    def create_schedule(self,schedule: dict):
        result = db[
            DOCTOR_SCHEDULES_COLLECTION
        ].insert_one(schedule)

        return result.inserted_id


    def update_schedule(self,doctor_id: str,data: dict):
        db[DOCTOR_SCHEDULES_COLLECTION].update_one(
            {
                "doctor_id": doctor_id
            },
            {
                "$set": data
            }
        )

    def find_by_doctor_id(self,doctor_id: str):
        return db[DOCTOR_SCHEDULES_COLLECTION].find_one(
            {
                "doctor_id": doctor_id
            }
        )

doctor_schedule_repository = DoctorScheduleRepository()


doctor_repository = DoctorRepository()