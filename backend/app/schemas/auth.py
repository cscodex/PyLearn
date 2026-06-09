import uuid
from typing import Optional
from pydantic import BaseModel, EmailStr, ConfigDict
from pydantic.alias_generators import to_camel

class CamelCaseBaseModel(BaseModel):
    model_config = ConfigDict(
        alias_generator=to_camel,
        populate_by_name=True,
        from_attributes=True
    )

class Token(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"

class TokenPayload(BaseModel):
    sub: Optional[str] = None
    exp: Optional[int] = None
    type: Optional[str] = None

class UserLogin(CamelCaseBaseModel):
    email: EmailStr
    password: str

class UserCreate(CamelCaseBaseModel):
    email: EmailStr
    password: str
    full_name: str

class UserResponse(CamelCaseBaseModel):
    id: uuid.UUID
    email: EmailStr
    full_name: str
    role: str
    is_active: bool
    email_verified: bool

class RefreshTokenRequest(CamelCaseBaseModel):
    refresh_token: str

class UserUpdate(CamelCaseBaseModel):
    full_name: Optional[str] = None
    email: Optional[EmailStr] = None
    profile_picture_url: Optional[str] = None

class PasswordUpdate(CamelCaseBaseModel):
    current_password: str
    new_password: str
