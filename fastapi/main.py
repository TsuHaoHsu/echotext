from fastapi import FastAPI, HTTPException, status, Query
from login_verification import create_login_token
from fastapi.responses import JSONResponse
from typing import Optional
from pydantic import BaseModel, EmailStr
from pymongo import MongoClient
from typing import List, Dict
from motor.motor_asyncio import AsyncIOMotorClient
import bcrypt
import jwt
from db import database  # Import the database from db.py
from datetime import datetime
from login_verification import router as auth_router
import redis

app = FastAPI()
app.include_router(auth_router)
r = redis.Redis(host='localhost', port=6379, db=0)

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

class Message(BaseModel):
    message_id: Optional[str]
    sender_id: str
    receiver_id: str
    content: Optional[str]
    timestamp: datetime
    imageUrl: Optional[str]
    type: str
    edited: bool
    edited_at: Optional[datetime] = None
    reactions: Dict[str,int] = {}
    read_status: bool

class Friendship(BaseModel):
    user1_id: str
    user2_id: str
    status: str  # "pending", "accepted", "rejected"
    initiated_at: datetime
    accepted_at: Optional[datetime] = None

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
    
@app.get("/message-history/", response_model=List[Message])
async def get_message_history(sender_id: str, receiver_id: str):
    
    messages = await database["message"].find({
        "$or": [
            {"sender_id": sender_id, "receiver_id": receiver_id},
            {"receiver_id": receiver_id, "sender_id": sender_id},
        ]
    }).sort("timestamp", -1).limit(20).to_list(None)
    
    return {"messages": messages}

@app.post("/friend-request/")
async def send_friend_request(request: FriendRequest):
    sender_id = request.sender_id
    receiver_id = request.receiver_id
    
    # Check if a pending request already exists between these two users
    existing_request = await database["pending"].find_one({
        "$or": [
            {"sender_id": sender_id, "receiver_id": receiver_id, "status": "pending"},
            {"sender_id": receiver_id, "receiver_id": sender_id, "status": "pending"}
        ]
    })
    
    if existing_request:
        # If a pending request exists, delete it (cancel the request)
        await database["pending"].delete_one({
            "$or": [
                {"sender_id": sender_id, "receiver_id": receiver_id, "status": "pending"},
                {"sender_id": receiver_id, "receiver_id": sender_id, "status": "pending"}
            ]
        })
        
        # Invalidate the cache for this request
        cache_key = f"pending:{sender_id}:{receiver_id}"
        r.delete(cache_key)  # Clear the cache to reflect fresh data
        
        return {"message": "Friend request cancelled."}
    
    # Otherwise, create a new pending request
    request_data = {
        "sender_id": sender_id,
        "receiver_id": receiver_id,
        "status": "pending",  # Pending status for new requests
        "initiated_at": datetime.now(),
    }
    
    result = await database["pending"].insert_one(request_data)
    
    if result.inserted_id:
        # Invalidate the cache for this new request
        cache_key = f"pending:{sender_id}:{receiver_id}"
        r.delete(cache_key)  # Clear the cache to reflect fresh data
        
        return {
            "friendship_id": str(result.inserted_id),
            "status": "pending",
            "receiver": receiver_id
        }
    
    raise HTTPException(status_code=500, detail="Failed to send friend request.")

@app.get("/request-query/")
async def get_pending_request(sender_id: str, receiver_id: str):
    
    # Generate a unique cache key for the pair of users
    cache_key = f"pending:{sender_id}:{receiver_id}"
    cached_data = r.get(cache_key)
    
    if cached_data:
        return {"message": cached_data.decode("utf-8")}
    
    existing_request = await database["pending"].find_one({
        "$or": [
            {"sender_id": sender_id, "receiver_id": receiver_id, "status": "pending"},
            {"sender_id": receiver_id, "receiver_id": sender_id, "status": "pending"},
        ]
    })
    
    if existing_request:
        # If a pending request exists, cache the result
        r.setex(cache_key, 300, "pending")  # Cache for 5 minutes
        
        # Return the pending status along with the sender and receiver ids
        return {"message": "pending", "sender_id": sender_id, "receiver_id": receiver_id}
    
    # If no request is found, cache the result as 'no pending request' for 5 minutes
    r.setex(cache_key, 300, "no pending request")
    return {"message": "no pending request", "sender_id": sender_id, "receiver_id": receiver_id}

@app.post("/accept-friend-request/")
async def accept_friend_request(friendship_id: str):
    
    # result = await database["friendship"].update_one(
    #     {"id_": friendship_id,"status": "pending"},
    #     {"$set": {"status": "accepted", "accepted_at": datetime.now()}}
    # )
    
    pending_request = await database["pending"].find_one({
        # ObjectId is for converting friendship_id back to mongodb object id
        "_id": ObjectId(friendship_id), "status": "pending",
    })
    
    if not pending_request:
        raise HTTPException(status_code=404, detail="Pending friend request not found.")
    
    friendship = {
        "sender_id": pending_request["sender_id"],
        "receiver_id": pending_request["receiver_id"],
        "status": "accepted",
        "initiated_at": pending_request["initiated_at"],
        "accepted_at": datetime.now(),
    }
    
    result = await database["friendship"].insert_one(friendship)
    
    if result.modified_count:
        return {"status": "accepted"}
    raise HTTPException(status_code=400, detail="Friend request not found or already accepted.")



@app.post("/reject-friend-request/")
async def reject_friend_request(friendship_id: str):
    
    result = await database["pending"].delete_one(
        {"id_": friendship_id}
    )
    if result.deleted_count:
        return {"status": "rejected"}
    raise HTTPException(status_code=404, detail="Friend request not found or already rejected.")

@app.delete("/remove-friend/{friendship_id}")
async def remove_friend(friendship_id: str):
    
    result = await database["friendship"].delete_one(
        {"id_": friendship_id}
    )
    if result.deleted_count:
        return "Success"
    raise HTTPException(status_code=400, detail="Friend not found or already removed.")

@app.get("/friend-list/")
async def get_friend_list(user_id: str):
    
    pipeline = [
        {
            "$match": {
                "$or": [
                    {"sender_id": user_id, "status": "accepted"},
                    {"receiver_id": user_id, "status": "accepted"}
                ]
            }
        },
        {
            "$lookup": {
                "from": "users",  # The collection to join with
                "localField": "sender_id",  # Field from the friendship document
                "foreignField": "user_id",  # Field from the user document
                "as": "sender_id_details"  # Output field to store user details
            }
        },
        {
            "$lookup": {
                "from": "users",
                "localField": "receiver_id",
                "foreignField": "user_id",
                "as": "receiver_id_details"
            }
        },
        {
            "$project": {
                "_id": 0,
                "friendship_id": "$_id",  # Add friendship_id to the projection
                "friend_details": {
                    "$concatArrays": ["$sender_id_details", "$receiver_id_details"]
                }
            }
        },
        {
            "$unwind": "$friend_details"
        },
        {
            "$project": {
                "friendship_id": 1,
                "user_id": "$friend_details.user_id",
                "name": "$friend_details.name"
            }
        }
    ]
    
    friends = await database["friendship"].aggregate(pipeline).to_list(None)
    friend_list = []

    for friendship in friends:
        # Collect both user_id and name for each friend
        if friendship["sender_id"] != user_id:
            friend_list.append({
                "friendship_id": friendship["friendship_id"],
                "user_id": friendship["sender_id"],
                "name": friendship["sender_id_details"][0]["name"]  # Use sender details
            })
        if friendship["receiver_id"] != user_id:
            friend_list.append({
                "friendship_id": friendship["friendship_id"],
                "user_id": friendship["receiver_id"],
                "name": friendship["receiver_id_details"][0]["name"]  # Use receiver details
            })

    return {"friends": friend_list}

    
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