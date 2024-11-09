from fastapi import APIRouter, HTTPException
from datetime import datetime, timedelta
from typing import Optional
import jwt

SECRET_KEY = "JasonStrongSuper"
ALGORITHM = "HS256"

router = APIRouter()

def create_login_token(user_id: str, email: str, password_version: int) -> dict:
    
    # Access token
    access_expire = datetime.now() + timedelta(hours=1)
    access_token = jwt.encode({
        "sub": user_id,
        "email": email,
        "password_version": password_version,
        "exp": access_expire,
    }, SECRET_KEY, algorithm = ALGORITHM)
    
    # Refresh token
    refresh_expire = datetime.now() + timedelta(days=30)
    refresh_token = jwt.encode({
        "sub": user_id,
        "email": email,
        "exp": refresh_expire,
    }, SECRET_KEY, algorithm = ALGORITHM)
    
    return {
    "access_token": access_token,
    "refresh_token": refresh_token
    }
    
@router.post("/user/refresh-token")
async def refresh_token(refresh_token: str):
    try:
        
        # Decode access token
        payload = jwt.decode(refresh_token, SECRET_KEY, algorithms=[ALGORITHM])
        user_id = payload["sub"]
        email = payload["email"]
        password_version = payload.get("password_version", 1) # 1 for default in case empty
        
        # Generate a new access token
        access_expire = datetime.now() + timedelta(hours=1)
        new_access_token = jwt.encode({
            "sub": user_id,
            "email": email,
            "password_version": password_version,
        }, SECRET_KEY, algorithm=ALGORITHM)
        
        return {"access_token": new_access_token}
    
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Refresh token expired")
    except jwt.InvalidTokenError:
        raise HTTPException(status_code=401, detail="Invalid refresh token")
    