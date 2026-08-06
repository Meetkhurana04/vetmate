from pymongo import MongoClient
from pymongo.errors import OperationFailure

from app.config.settings import settings

client = MongoClient(settings.MONGO_URI)

db = client[settings.DATABASE_NAME]

# Unique index to prevent double-booking a slot. It is a PARTIAL index so it
# only covers "BOOKED" appointments. Cancelled appointments are excluded from
# the index, which lets a patient re-book a slot that was previously cancelled.
# (A full unique index on these 3 fields would block re-booking forever because
# cancelled docs stay in the collection.)
index_name = "doctor_id_1_appointment_date_1_start_time_1"

try:
    existing = db.appointments.index_information()
    if index_name in existing:
        db.appointments.drop_index(index_name)
except OperationFailure:
    pass

db.appointments.create_index(
    [
        ("doctor_id", 1),
        ("appointment_date", 1),
        ("start_time", 1),
    ],
    unique=True,
    partialFilterExpression={"status": "BOOKED"},
    name="unique_booked_slot",
)
