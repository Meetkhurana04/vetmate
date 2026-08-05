from app.config.database import db
from bson import ObjectId

class UserRepository:
    def find_by_email(self, email: str):
        return db.users.find_one({
            "email": email
        })

    def create_user(self, user: dict):
        result = db.users.insert_one(user)
        return result.inserted_id

    def find_by_id(user_id: str):
        return db.users.find_one(
            {
                "_id": ObjectId(user_id)
            }
        )
    
user_repository = UserRepository()