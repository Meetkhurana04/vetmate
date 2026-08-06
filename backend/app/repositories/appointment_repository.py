from app.config.database import db
from app.constants.collections import APPOINTMENTS_COLLECTION
from bson import ObjectId

class AppointmentRepository:
    def get_booked_slots(self,doctor_id: str,appointment_date):
        return list(
            db[APPOINTMENTS_COLLECTION].find(
                {
                    "doctor_id": doctor_id,
                    "appointment_date": str(appointment_date),
                    "status": "BOOKED"
                },
                {
                    "_id": 0,
                    "start_time": 1
                }
            )
        )

    def create_appointment(self,appointment: dict):
        result = db[
            APPOINTMENTS_COLLECTION
        ].insert_one(
            appointment
        )
        return result.inserted_id

    def find_slot(self,doctor_id,appointment_date,start_time):
        return db[
            APPOINTMENTS_COLLECTION
        ].find_one(
            {
                "doctor_id":doctor_id,
                "appointment_date":str(
                    appointment_date
                ),
                "start_time":start_time,
                "status":"BOOKED"
            }
        )

    def create(self,appointment):
        result = db[
            APPOINTMENTS_COLLECTION
        ].insert_one(
            appointment
        )

        return result.inserted_id

    def find_by_patient(self,patient_id: str):
        return list(
            db[
                APPOINTMENTS_COLLECTION
            ].find(
                {
                    "patient_id": patient_id
                }
            ).sort(
                "appointment_date",
                1
            )
        )

    def find_by_doctor(self, doctor_id: str):
        return list(
            db[APPOINTMENTS_COLLECTION].find(
                {
                    "doctor_id": doctor_id
                }
            ).sort(
                "appointment_date",
                1
            )
        )

    def cancel(self,appointment_id):
        return db[
            APPOINTMENTS_COLLECTION
        ].update_one(
            {
                "_id": ObjectId(
                    appointment_id
                )
            },
            {
                "$set":{
                    "status":"CANCELLED"
                }
            }
        )

appointment_repository = AppointmentRepository()