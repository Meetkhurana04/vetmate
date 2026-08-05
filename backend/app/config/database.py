from pymongo import MongoClient

from app.config.settings import settings

client = MongoClient(settings.MONGO_URI)

db = client[settings.DATABASE_NAME]

db.appointments.create_index(
    [

        ("doctor_id",1),

        ("appointment_date",1),

        ("start_time",1)

    ],
    unique=True
)