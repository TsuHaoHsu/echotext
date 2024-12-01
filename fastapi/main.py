import json
from fastapi import FastAPI, HTTPException, status, Query
from login_verification import create_login_token
from fastapi.responses import JSONResponse
from typing import Optional
from pydantic import BaseModel, EmailStr, Field
from pymongo import MongoClient
from typing import List, Dict
from motor.motor_asyncio import AsyncIOMotorClient
from db import database  # Import the database from db.py
from datetime import datetime
from login_verification import router as auth_router
from json import dumps, loads
from bson import ObjectId
from fastapi import WebSocket, WebSocketDisconnect
# from fastapi.middleware.cors import CORSMiddleware
from collections import defaultdict
import redis
import bcrypt
import jwt
import os
import websockets
import traceback

app = FastAPI()
app.include_router(auth_router)
#r = redis.Redis(host='localhost', port=6379, db=0)

#MONGODB_URL = "mongodb://localhost:27017"
#MONGODB_URL = "mongodb://192.168.0.195:27017"
MONGODB_URL = os.getenv("MONGODB_URL", "mongodb://localhost:27017")

client = AsyncIOMotorClient(MONGODB_URL)
database = client["Echo_Text_Local"]

class User(BaseModel):
    name: str
    email: EmailStr
    password: str = Field(..., min_length=6)
    isVerified: bool = True
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
    sender_id: str
    receiver_id: str
    content: Optional[str] = None
    imageUrl: Optional[str] = None
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

# app.add_middleware(
#     CORSMiddleware,
#     allow_origins=["https://a026-2407-4d00-3c00-9143-add2-a8fb-150b-cdd5.ngrok-free.app/"],  # Add your ngrok URL here
#     allow_credentials=True,
#     allow_methods=["*"],  # Allows all HTTP methods
#     allow_headers=["*"],  # Allows all headers
# )

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
    
@app.get("/get-message/", response_model=List[Message])
async def get_message(sender_id: str, receiver_id: str, skip: int = 0, limit: int = 20):
    messages = await database["message"].find({
        "$or": [
            {"sender_id": sender_id, "receiver_id": receiver_id},
            {"sender_id": receiver_id, "receiver_id": sender_id},
        ]
    }).sort("timestamp", -1).skip(skip).limit(limit).to_list(None)

    # Convert _id to message_id for all messages
    for message in messages:
        message["message_id"] = str(message["_id"])
        del message["_id"]
        if message.get("imageUrl") is None:
            message["imageUrl"] = ""  # Replace null with empty string

    # Ensure the response is serialized as expected
    return [dict(message) for message in messages]  # Explicit conversion to dict

active_connections = defaultdict(list)

@app.websocket("/ws/messages/{sender_id}/{receiver_id}")
async def websocket_endpoint(websocket: WebSocket, sender_id: str, receiver_id: str):
    await websocket.accept()

    print(f"WebSocket connected: Sender {sender_id}, Receiver {receiver_id}")
    
    connection_key_sender_to_receiver = (sender_id, receiver_id)
    connection_key_receiver_to_sender = (receiver_id, sender_id)

    # Ensure the connection key exists in active_connections for both sender-to-receiver and receiver-to-sender
    if connection_key_sender_to_receiver not in active_connections:
        active_connections[connection_key_sender_to_receiver] = []

    if connection_key_receiver_to_sender not in active_connections:
        active_connections[connection_key_receiver_to_sender] = []
        
    # Add the WebSocket connection to both the sender-to-receiver and receiver-to-sender lists
    active_connections[connection_key_sender_to_receiver].append({
        'websocket': websocket,
        'sender_id': sender_id,
        'receiver_id': receiver_id
    })
    active_connections[connection_key_receiver_to_sender].append({
        'websocket': websocket,
        'sender_id': sender_id,
        'receiver_id': receiver_id
    })
    
    print(f"Connection added: Sender {sender_id}, Receiver {receiver_id}")
    print(active_connections)

    try:
        # Fetch message history
        messages = await get_message(sender_id, receiver_id)
        serialized_messages = [serialize_message(message) for message in messages]
        
        # Send message history to both directions' WebSocket(s)
        for connection_key in [connection_key_sender_to_receiver, connection_key_receiver_to_sender]:
            if connection_key in active_connections:
                for connection in active_connections[connection_key]:
                    try:
                        ws = connection['websocket']
                        await ws.send_json({"message": serialized_messages})
                    except Exception as e:
                        print(f"Error sending message history: {e}")

        while True:
            try:
                #print("Waiting for message...")
                content = await websocket.receive_text()
                #print(f"Received message: {content}")

                content_json = json.loads(content)
                new_message = {
                    "sender_id": sender_id,
                    "receiver_id": receiver_id,
                    "content": content_json.get("content", ""),
                    "imageUrl": content_json.get("imageUrl"),
                    "timestamp": datetime.now().isoformat(),
                }

                # Insert message into the database
                result = await database["message"].insert_one(new_message)
                new_message["message_id"] = str(result.inserted_id)  # Convert ObjectId to string
                serialized_new_message = serialize_message(new_message)
                        
                # Send message to both side
                for connection_key in [connection_key_sender_to_receiver, connection_key_receiver_to_sender]:
                    if connection_key in active_connections:
                        for ws in active_connections[connection_key]:
                            await ws['websocket'].send_json({"new_message": serialized_new_message})
                            
                            
                print(f"Active connections: {active_connections}")
                print(type(active_connections))

            except WebSocketDisconnect:
                print(f"WebSocket disconnected for {sender_id} -> {receiver_id}")
                break

            except Exception as e:
                print(f"Error occurred during WebSocket handling: {e}")
                traceback.print_exc()
                break

    finally:
        # Remove this WebSocket from both sender-to-receiver and receiver-to-sender active connections
        for connection_key in [connection_key_sender_to_receiver, connection_key_receiver_to_sender]:
            if connection_key in active_connections:
                active_connections[connection_key] = [
                    conn for conn in active_connections[connection_key] if conn['websocket'] != websocket
                ]
                if not active_connections[connection_key]:
                    del active_connections[connection_key]
                    print(f"Final cleanup: Removed {connection_key} from active connections.")


def serialize_message(message):
    """Converts MongoDB message fields for JSON compatibility."""
    if "_id" in message:
        message["message_id"] = str(message["_id"])
        del message["_id"]
    if "timestamp" in message and isinstance(message["timestamp"], datetime):
        message["timestamp"] = message["timestamp"].isoformat()
    return message

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