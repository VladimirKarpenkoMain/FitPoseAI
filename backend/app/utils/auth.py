from datetime import datetime, timedelta, UTC
from typing import Annotated

import bcrypt
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt
from sqlalchemy.orm import Session

from app.config import settings
from app.database import get_db
from app.models.user import User
from app.schemas.user import TokenData
from app.utils.logger import logger

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/login")


def hash_password(password: str) -> str:
    """Hash a password using bcrypt."""
    password_bytes = password.encode('utf-8')
    salt = bcrypt.gensalt()
    hashed = bcrypt.hashpw(password_bytes, salt)
    return hashed.decode('utf-8')


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify a password against a bcrypt hash."""
    password_bytes = plain_password.encode('utf-8')
    hashed_bytes = hashed_password.encode('utf-8')
    return bcrypt.checkpw(password_bytes, hashed_bytes)


def _create_token(data: dict, expires_delta: timedelta, token_type: str) -> str:
    """Create a typed JWT token."""
    to_encode = data.copy()
    expire = datetime.now(UTC) + expires_delta
    to_encode.update({"exp": expire, "type": token_type})
    
    logger.debug(f"Creating token with data: {to_encode}")
    token = jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
    logger.info(f"Token created for user: {data.get('sub')}")
    return token


def create_access_token(data: dict) -> str:
    """Create a JWT access token."""
    return _create_token(
        data,
        timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES),
        "access",
    )


def create_refresh_token(data: dict) -> str:
    """Create a JWT refresh token."""
    return _create_token(
        data,
        timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS),
        "refresh",
    )


def decode_refresh_token(token: str) -> TokenData:
    """Decode and validate a refresh token."""
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate refresh token",
        headers={"WWW-Authenticate": "Bearer"},
    )

    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        if payload.get("type") != "refresh":
            raise credentials_exception

        user_id_str: str | None = payload.get("sub")
        if user_id_str is None:
            raise credentials_exception

        return TokenData(user_id=int(user_id_str))
    except (JWTError, ValueError) as e:
        logger.error(f"Refresh token validation error: {e}")
        raise credentials_exception


def get_current_user(
    token: Annotated[str, Depends(oauth2_scheme)],
    db: Annotated[Session, Depends(get_db)]
) -> User:
    """Get the current authenticated user from JWT token."""
    logger.debug(f"Validating token: {token[:50]}...")
    
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        logger.debug(f"Decoded payload: {payload}")

        if payload.get("type", "access") != "access":
            logger.warning("Non-access token used for authentication")
            raise credentials_exception
        
        user_id_str: str | None = payload.get("sub")
        logger.debug(f"User ID from token: {user_id_str} (type: {type(user_id_str)})")
        
        if user_id_str is None:
            logger.warning("User ID is None in token payload")
            raise credentials_exception
        
        # Convert string to int
        user_id = int(user_id_str)
        token_data = TokenData(user_id=user_id)
        
    except JWTError as e:
        logger.error(f"JWT validation error: {e}")
        raise credentials_exception

    user = db.query(User).filter(User.id == token_data.user_id).first()
    logger.debug(f"User query result for ID {token_data.user_id}: {user}")
    
    if user is None:
        logger.warning(f"User not found in database: ID {token_data.user_id}")
        raise credentials_exception
        
    logger.info(f"User authenticated successfully: {user.email}")
    return user
