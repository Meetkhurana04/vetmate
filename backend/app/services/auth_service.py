from fastapi import HTTPException, status
from fastapi.responses import JSONResponse
from app.repositories.user_repository import user_repository
from app.utils.password import hash_password, verify_password
from app.utils.jwt import create_access_token

class AuthService:
    def register(self, data):
        existing_user = user_repository.find_by_email(
            data.email
        )

        if existing_user:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Email already registered"
            )

        user = {
            "name": data.name,
            "email": data.email,
            "phone": data.phone,
            "password": hash_password(
                data.password
            ),
            "role": data.role,
            "latitude": data.latitude,
            "longitude": data.longitude,
            "leaves": []
        }

        user_id = user_repository.create_user(
            user
        )

        # Upsert clinic document for doctor so they are immediately active and bookable
        if data.role == "DOCTOR":
            from app.config.database import db
            clinic_name = f"Dr. {data.name}'s Clinic"
            doctor_name = f"Dr. {data.name}" if not data.name.startswith("Dr. ") else data.name
            
            clinic_data = {
                "id": f"c_{user_id}",
                "name": clinic_name,
                "doctorName": doctor_name,
                "latitude": data.latitude or 26.9124,
                "longitude": data.longitude or 75.7873,
                "rating": 4.5,
                "address": "Jaipur",
                "isOpen": True,
                "image": "assets/images/happy_paws.png",
                "doctor_id": str(user_id)
            }
            db.clinics.update_one(
                {"doctor_id": str(user_id)},
                {"$set": clinic_data},
                upsert=True
            )

        token = create_access_token({
            "user_id": str(user_id),
            "role": data.role
        })

        return JSONResponse(
            status_code=status.HTTP_201_CREATED,
            content={
                "message": "Registration Successful",
                "access_token": token,
                "refresh_token": token,
                "token_type": "bearer",
                "user": {
                    "id": str(user_id),
                    "name": data.name,
                    "role": data.role,
                    "email": data.email,
                    "phone": data.phone,
                    "latitude": data.latitude,
                    "longitude": data.longitude,
                    "leaves": []
                }
            }
        )

    def login(self, data):
        user = user_repository.find_by_email(data.email)
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )

        if not verify_password(
            data.password,
            user["password"]
        ):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid credentials"
            )

        if data.role and user.get("role") != data.role:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Unauthorized: Wrong Credentials."
            )

        # Upsert clinic document for doctor if not exists on login (fail-safe)
        if user.get("role") == "DOCTOR":
            from app.config.database import db
            clinic = db.clinics.find_one({"doctor_id": str(user["_id"])})
            clinic_name = f"Dr. {user['name']}'s Clinic"
            doctor_name = f"Dr. {user['name']}" if not user['name'].startswith("Dr. ") else user['name']
            
            clinic_data = {
                "id": clinic["id"] if clinic else f"c_{user['_id']}",
                "name": clinic.get("name") if clinic else clinic_name,
                "doctorName": clinic.get("doctorName") if clinic else doctor_name,
                "latitude": user.get("latitude") or (clinic.get("latitude") if clinic else 26.9124),
                "longitude": user.get("longitude") or (clinic.get("longitude") if clinic else 75.7873),
                "rating": clinic.get("rating") if clinic else 4.5,
                "address": clinic.get("address") if clinic else "Jaipur",
                "isOpen": True,
                "image": clinic.get("image") if clinic else "assets/images/happy_paws.png",
                "doctor_id": str(user["_id"])
            }
            db.clinics.update_one(
                {"doctor_id": str(user["_id"])},
                {"$set": clinic_data},
                upsert=True
            )

        token = create_access_token({
            "user_id": str(user["_id"]),
            "role": user["role"]
        })

        return {
            "access_token": token,
            "refresh_token": token,
            "token_type": "bearer",
            "user": {
                "id": str(user["_id"]),
                "name": user["name"],
                "role": user["role"],
                "email": user["email"],
                "phone": user.get("phone", ""),
                "latitude": user.get("latitude"),
                "longitude": user.get("longitude"),
                "leaves": user.get("leaves", [])
            }
        }

    def update_profile(self, current_user, data):
        from app.config.database import db
        
        update_fields = {}
        if data.name is not None:
            update_fields["name"] = data.name
        if data.phone is not None:
            update_fields["phone"] = data.phone
        if data.latitude is not None:
            update_fields["latitude"] = data.latitude
        if data.longitude is not None:
            update_fields["longitude"] = data.longitude
            
        if update_fields:
            db.users.update_one(
                {"_id": current_user["_id"]},
                {"$set": update_fields}
            )
            
        # Refetch user
        updated_user = db.users.find_one({"_id": current_user["_id"]})
        
        # Upsert/Sync clinic document for DOCTOR role
        if updated_user["role"] == "DOCTOR":
            clinic = db.clinics.find_one({"doctor_id": str(updated_user["_id"])})
            clinic_name = f"Dr. {updated_user['name']}'s Clinic"
            doctor_name = f"Dr. {updated_user['name']}" if not updated_user['name'].startswith("Dr. ") else updated_user['name']
            
            clinic_data = {
                "id": clinic["id"] if clinic else f"c_{updated_user['_id']}",
                "name": clinic_name,
                "doctorName": doctor_name,
                "latitude": updated_user.get("latitude") or 26.9124,
                "longitude": updated_user.get("longitude") or 75.7873,
                "rating": clinic.get("rating") if clinic else 4.5,
                "address": clinic.get("address") if clinic else "Jaipur",
                "isOpen": True,
                "image": clinic.get("image") if clinic else "assets/images/happy_paws.png",
                "doctor_id": str(updated_user["_id"])
            }
            db.clinics.update_one(
                {"doctor_id": str(updated_user["_id"])},
                {"$set": clinic_data},
                upsert=True
            )
        
        return {
            "message": "Profile updated successfully",
            "user": {
                "id": str(updated_user["_id"]),
                "name": updated_user["name"],
                "role": updated_user["role"],
                "email": updated_user["email"],
                "phone": updated_user.get("phone", ""),
                "latitude": updated_user.get("latitude"),
                "longitude": updated_user.get("longitude"),
                "leaves": updated_user.get("leaves", [])
            }
        }

    def manage_leave(self, current_user, data):
        from app.config.database import db
        
        date_str = data.date.strip()
        action = data.action.upper()
        
        if action == "TAKE":
            db.users.update_one(
                {"_id": current_user["_id"]},
                {"$addToSet": {"leaves": date_str}}
            )
        else:
            db.users.update_one(
                {"_id": current_user["_id"]},
                {"$pull": {"leaves": date_str}}
            )
            
        updated_user = db.users.find_one({"_id": current_user["_id"]})
        return {
            "message": "Leave modified successfully",
            "leaves": updated_user.get("leaves", [])
        }

auth_service = AuthService()