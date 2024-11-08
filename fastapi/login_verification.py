import jwt
from datetime import datetime, timedelta
from typing import Optional

SECRET_KEY = "JasonStrongSuper"
ALGORITHM = "HS256"

#def create_login_token(user_id: str, email: str, expires_delta: Optional[timedelta] = None ) -> str:
def create_login_token(user_id: str, email: str, password_version: int) -> str:
    
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
    
    return {"access_token": access_token, "refresh_token": refresh_token}
    