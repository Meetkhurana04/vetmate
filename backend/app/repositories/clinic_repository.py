from app.config.database import db

class ClinicRepository:
    def create_clinic(self, clinic_data: dict):
        # We use the 'id' passed from frontend, but we can also set _id to it
        if "id" in clinic_data and "_id" not in clinic_data:
            clinic_data["_id"] = clinic_data["id"]
        result = db.clinics.insert_one(clinic_data)
        return result.inserted_id

    def find_all(self):
        return list(db.clinics.find({}))

    def find_by_id(self, clinic_id: str):
        return db.clinics.find_one({"id": clinic_id})

    def find_by_doctor_id(self, doctor_id: str):
        return list(db.clinics.find({"doctor_id": doctor_id}))

clinic_repository = ClinicRepository()
