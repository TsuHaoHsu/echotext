from fastapi import FastAPI, HTTPException
from typing import Optional
from datetime import datetime
from pydantic import BaseModel
from pymongo import MongoClient
from typing import List
from motor.motor_asyncio import AsyncIOMotorClient
import bcrypt
from db import database  # Import the database from db.py

app = FastAPI()
#MONGODB_URL = "mongodb://localhost:27017"
MONGODB_URL = "mongodb://192.168.0.195:27017"
client = AsyncIOMotorClient(MONGODB_URL)
database = client["Echo_Text_Local"]


class User(BaseModel):
    name: str
    email: str
    password: str
    
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
    
    result = await database["users"].insert_one(user.dict()) #convert user from python object to dictionary format
    if result.inserted_id: #if there's result
        return {"id": str(result.inserted_id), "name": user.name, "email": user.email}
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