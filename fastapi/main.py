from fastapi import FastAPI, HTTPException, status
from login_verification import create_login_token
from fastapi.responses import JSONResponse
from typing import Optional
from pydantic import BaseModel, EmailStr
from pymongo import MongoClient
from typing import List
from motor.motor_asyncio import AsyncIOMotorClient
import bcrypt
import jwt
from db import database  # Import the database from db.py
from datetime import datetime
from login_verification import router as auth_router


app = FastAPI()
app.include_router(auth_router)

#MONGODB_URL = "mongodb://localhost:27017"
MONGODB_URL = "mongodb://192.168.0.195:27017"
client = AsyncIOMotorClient(MONGODB_URL)
database = client["Echo_Text_Local"]

class User(BaseModel):
    name: str
    email: EmailStr
    password: str
    isVerified: bool = False
    password_version: int = 1
    
class UserQuery(BaseModel):
    name: str
    email: EmailStr
    
class UserLogin(BaseModel):
    email: EmailStr
    password: str
    #isVerified: bool
    
class Message(BaseModel):
    message_id: Optional[str]
    sender_id: str
    receiver_id: str
    content: Optional[str]
    timestamp: datetime
    imageUrl: Optional[str]

@app.get("/test/")
async def test_connection():
    try:
        await database.command("ping")
        return {"message": "Connection successful!"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Connection failed: {str(e)}")

@app.post("/user/")
async def create_user(user: User):
    
    existing_user = await database["users"].find_one({"email": user.email})
    if existing_user:
        raise HTTPException(status_code=400, detail="User with this email already exists.")
    
    hashed_password = bcrypt.hashpw(user.password.encode(), bcrypt.gensalt())
    user_data = user.dict() # converts user to dictionary format
    user_data["password"] = hashed_password.decode()
    
    result = await database["users"].insert_one(user_data) #convert user from python object to dictionary format
    if result.inserted_id: #if there's result
        return {"id": str(result.inserted_id), "name": user.name, "email": user.email, "isVerified": user.isVerified}
    raise HTTPException(status_code=500, detail="User could not be created.")

@app.post("/message/")
async def create_message(message: Message):
    
    if not (message.content or message.imageUrl):
        raise HTTPException(status_code=400, detail="Message must contain either text or image.")
    
    result = await database["message"].insert_one(message.dict())
    if result.inserted_id:
        return {
            "message_id": str(result.inserted_id),
            "sender_id": message.sender_id,
            "receiver_id": message.receiver_id,
            "content": message.content,
            "timestamp": message.timestamp,
            "imageurl": message.imageUrl,
        }
    raise HTTPException(status_code=500, detail="Message could not be created.")

@app.get("/user/{user_id}")
async def get_user(user_id: str):
    user = await database["users"].find_one({"_id": user_id})
    if user:
        user["_id"] = str(user["_id"])
        return user
    raise HTTPException(status_code=404, detail="User not found")

@app.post("/user/login")
async def login_user(user: UserLogin):
    user_record = await database["users"].find_one({"email": user.email})
    
    
    try:
        if user_record:
            
            #if user_record["password"] != user.password:
            if not bcrypt.checkpw(user.password.encode(), user_record["password"].encode()):
                raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Incorrect Password"
                )
            
            elif not user_record["isVerified"]:
                raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Email not yet verified"
                )
            
            elif bcrypt.checkpw(user.password.encode(), user_record["password"].encode()) and user_record["isVerified"]:
                
                tokens = create_login_token(str(user_record["_id"]), user_record["email"], user_record["password_version"])
                
                return {
                    "message": "Success",
                    "id": str(user_record["_id"]),  # Ensure you're returning the user's ID
                    "name": user_record["name"],
                    "isVerified": user_record["isVerified"],
                    "access_token": tokens["access_token"],
                    "refresh_token": tokens["refresh_token"],
                }
                
                
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User does not exist"
        )
            
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.get("/users/")
async def get_all_users():

    users = await database["users"].find().to_list(length=None)
    for user in users:
        user["_id"] = str(user["_id"])
    return users
    
@app.get("/messages/", response_model=List[Message])
async def get_messages(sender_id: str = None, receiver_id: str = None):
    query = {}
    
    if sender_id:
        query["sender_id"] = sender_id
    if receiver_id:
        query["receiver_id"] = receiver_id
    
    messages = []
    async for message in database["message"].find(query):
        message["message_id"] = str(message["_id"])
        messages.append(message)
    
    return messages

'''
@app.get("/verify/{token}")
async def verify_email(token: str):
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=["HS256"])
        email = payload["email"]
        # Here you can update your MongoDB to mark the user as verified
        database["users"].update_one({"email": email}, {"$set": {"isVerified": True}})
        return JSONResponse(content={"message": "Email verified successfully."}, status_code=200)
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=400, detail="Token expired")
    except jwt.JWTError:
        raise HTTPException(status_code=400, detail="Invalid token")'''