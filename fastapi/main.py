from fastapi import FastAPI, HTTPException, status, Query
from login_verification import create_login_token
from fastapi.responses import JSONResponse
from typing import Optional
from pydantic import BaseModel, EmailStr
from pymongo import MongoClient
from typing import List, Dict
from motor.motor_asyncio import AsyncIOMotorClient
from db import database  # Import the database from db.py
from datetime import datetime
from login_verification import router as auth_router
from json import dumps, loads
from bson import ObjectId
from fastapi import WebSocket, WebSocketDisconnect
import redis
import bcrypt
import jwt

app = FastAPI()
app.include_router(auth_router)
#r = redis.Redis(host='localhost', port=6379, db=0)

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
    user_id: str
    name: str
    profile_picture: str = ""
    
    
class UserLogin(BaseModel):
    email: EmailStr
    password: str
    #isVerified: bool
    
class FriendRequest(BaseModel):
    sender_id: str
    receiver_id: str
    name: str

class Message(BaseModel):
    message_id: Optional[str]
    sender_id: str
    receiver_id: str
    content: Optional[str]
    timestamp: datetime
    imageUrl: Optional[str]
    # type: str
    # edited: bool
    # edited_at: Optional[datetime] = None
    # reactions: Dict[str,int] = {}
    # read_status: bool

class Friendship(BaseModel):
    user1_id: str
    user2_id: str
    status: str  # "pending", "accepted", "rejected"
    initiated_at: datetime
    accepted_at: Optional[datetime] = None

# def generate_cache_key(sender_id: str, receiver_id: str) -> str:
#     return f"pending:{min(sender_id, receiver_id)}:{max(sender_id, receiver_id)}"

# async def invalidate_pending_request_cache(sender_id: str, receiver_id: str):
#     cache_key = generate_cache_key(sender_id, receiver_id)
#     r.delete(cache_key)

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
        
        # add user to user_list
        try:
            await database["user_list"].insert_one({
                "user_id": str(result.inserted_id),
                "name": user.name,
                "profile_picture": None,
            })
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")
        
        return {
            "id": str(result.inserted_id),
            "name": user.name,
            "email": user.email,
            "isVerified": user.isVerified
        }
        
    raise HTTPException(status_code=500, detail="User could not be created.")

@app.post("/create-message/")
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
            "type": message.type,
            "edited": message.edited, # WIP
            "edited_at": message.edited_at, # WIP
            "reactions": message.reactions, # WIP
            "read_status": message.read_status,
        }
    raise HTTPException(status_code=500, detail="Message could not be created.")

@app.get("/user-list/", response_model=List[UserQuery])
async def get_user_list(query: Optional[str] = Query(None)):
    
    users_cursor = database["user_list"].find({
        "$or": [
            {"name": {"$regex": query, "$options": "i"}},
        ]
    })
    
    users = await users_cursor.to_list(length=20)
    
    if not users:
        raise HTTPException(status_code=404, detail = "No users found matching the query. ")
    
    return [
        {
            "user_id": str(user["user_id"]),
            "name": user["name"],
            "profile_picture": user.get("profile_picture", "") or "",
        }
        for user in users
    ]

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

@app.post("/send-message/")
async def send_message(message: Message):
    
    result = await database["message"].insert_one(message.dict())
    
    return {"message_id": str(result.inserted_id), "status": "sent"}
    
@app.get("/get-message/", response_model=List[Message])
async def get_message(sender_id: str, receiver_id: str):
    
    messages = await database["message"].find({
        "$or": [
            {"sender_id": sender_id, "receiver_id": receiver_id},
            {"receiver_id": receiver_id, "sender_id": sender_id},
        ]
    }).sort("timestamp", -1).limit(20).to_list(None)
    
    return messages

@app.websocket("/ws/messages/{sender_id}/{receiver_id}")
async def websocket_endpoint(websocket: WebSocket, sender_id: str, receiver_id: str):
    await websocket.accept()
    
    try:
        messages = await get_message(sender_id, receiver_id)
        await websocket.send_json({"message": messages})
        
        while True:
           data = await websocket.receive_text()
           
           new_message = {
               "sender_id": sender_id,
               "receiver_id": receiver_id,
               "message": data,
               "timestamp": datetime.now().isoformat(),
           }
           await database["message"].insert_one(new_message)
           
           await websocket.send_json({"new_message": new_message})
           
    except WebSocketDisconnect:
        print(f"User {sender_id} disconnected")

@app.websocket("/ws/messages/test")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    await websocket.send_text("Connection successful!")

@app.post("/friend-request/")
async def send_friend_request(request: FriendRequest):
    sender_id = request.sender_id
    receiver_id = request.receiver_id
    sender_name = request.name
    
    # Check for a pending request in the correct sender/receiver roles
    existing_request = await database["pending"].find_one({
        "sender_id": sender_id, 
        "receiver_id": receiver_id, 
        "sender_name": sender_name,
        "status": "pending",
    })
    
    if existing_request:
        # Cancel the existing request
        await database["pending"].delete_one({
            "sender_id": sender_id,
            "receiver_id": receiver_id,
            "status": "pending"
        })
        return {"message": "Friend request cancelled."}

    # Otherwise, create a new pending request
    request_data = {
        "sender_id": sender_id,
        "receiver_id": receiver_id,
        "sender_name": sender_name,
        "status": "pending",
        "initiated_at": datetime.now(),
    }
    
    result = await database["pending"].insert_one(request_data)
    if result.inserted_id:
        return {"friendship_id": str(result.inserted_id), "status": "pending"}
    
    raise HTTPException(status_code=500, detail="Failed to send friend request.")

@app.get("/request-query/")
async def get_pending_request(sender_id: str, receiver_id: str):
    
    sent_request = await database["pending"].find_one({
        "sender_id": sender_id, 
        "receiver_id": receiver_id, 
        "status": "pending"
    })
    
    if sent_request:
        return {"message": "pending_sent", "sender_id": sender_id, "receiver_id": receiver_id}
    
    # Check if the current user is the receiver of a pending request
    received_request = await database["pending"].find_one({
        "sender_id": receiver_id, 
        "receiver_id": sender_id, 
        "status": "pending"
    })
    
    if received_request:
        return {"message": "pending_received", "sender_id": receiver_id, "receiver_id": sender_id}
    
    # No pending request
    return {"message": "no pending request", "sender_id": sender_id, "receiver_id": receiver_id}

@app.post("/accept-friend-request/")
async def accept_friend_request(request: FriendRequest):
    
    sender_id = request.sender_id
    receiver_id = request.receiver_id
    receiver_name = request.name
    
    # Fetch the sender's name from the 'users' collection
    sender = await database["users"].find_one({"_id": ObjectId(sender_id)})
    if not sender:
        raise HTTPException(status_code=404, detail="Sender not found.")
    
    sender_name = sender["name"]
    
    delete_result = await database["pending"].delete_one({
        "$or": [
            {"sender_id": sender_id, "receiver_id": receiver_id, "status": "pending"},
            {"sender_id": receiver_id, "receiver_id": sender_id, "status": "pending"}
        ]
    })
    
    if delete_result.deleted_count == 0:
        raise HTTPException(status_code=404, detail="Pending friend request not found.")

    # Create a new friendship
    friendship = {
        "sender_id": sender_id,
        "sender_name": sender_name,
        "receiver_id": receiver_id,
        "receiver_name": receiver_name,
        "status": "accepted",
        "accepted_at": datetime.now(),
    }
    result = await database["friendship"].insert_one(friendship)
    if result.inserted_id:
        return {"status": "accepted"}
    
    raise HTTPException(status_code=400, detail="Failed to accept friend request.")

@app.post("/reject-friend-request/")
async def reject_friend_request(request: FriendRequest):
    sender_id = request.sender_id
    receiver_id = request.receiver_id

    # Delete the pending request
    delete_result = await database["pending"].delete_one({
        "$or": [
            {"sender_id": sender_id, "receiver_id": receiver_id, "status": "pending"},
            {"sender_id": receiver_id, "receiver_id": sender_id, "status": "pending"}
        ]
    })
    if delete_result.deleted_count == 0:
        raise HTTPException(status_code=404, detail="Pending friend request not found.")

    return {"message": "Friend request rejected."}

@app.delete("/remove-friend/{friendship_id}")
async def remove_friend(friendship_id: str):
    
    print(f"Received friendship_id: {friendship_id}")  # Log the friendship ID
    
    # Convert the friendship_id from string to ObjectId
    try:
        friendship_id_obj = ObjectId(friendship_id)
        print(f"Converted to ObjectId: {friendship_id_obj}")  # Log the ObjectId
    except Exception as e:
        raise HTTPException(status_code=400, detail="Invalid ObjectId format.")
    
    result = await database["friendship"].delete_one(
        {"_id": friendship_id_obj}
    )
    if result.deleted_count:
        return "Success"
    raise HTTPException(status_code=400, detail="Friend not found or already removed.")

@app.get("/friend-list/")
async def get_friend_list(user_id: str):
    # Query for all friendships where the user is either the sender or receiver
    cursor = database["friendship"].find({
        '$or': [
            {"sender_id": user_id, "status": "accepted"},
            {"receiver_id": user_id, "status": "accepted"}
        ]
    })
    
    friends = []
    
    # Iterate over the cursor asynchronously
    async for friendship in cursor:
        # Determine the friend to append (exclude user_id)
        if friendship["sender_id"] != user_id:
            friends.append({
                "friendship_id": str(friendship["_id"]),  # Include the friendship _id
                "friend_id": friendship["sender_id"],    # Friend's ID
                "friend_name": friendship["sender_name"]  # Friend's Name
            })
        else:
            friends.append({
                "friendship_id": str(friendship["_id"]),  # Include the friendship _id
                "friend_id": friendship["receiver_id"],   # Friend's ID
                "friend_name": friendship["receiver_name"] # Friend's Name
            })
    
    # Return the response with the serialized data
    return JSONResponse(content={"friends": friends})


    
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
        raise HTTPException(status_code=400, detail="Invalid token")
'''