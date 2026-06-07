from pydantic import BaseModel
from typing import Optional

class UserStatsResponse(BaseModel):
    id: int
    full_name: str
    email: str
    xp: int
    streak_days: int
    profile_picture_url: Optional[str]

class LeaderboardUser(BaseModel):
    id: int
    full_name: str
    xp: int
    profile_picture_url: Optional[str]
    rank: int

class LeaderboardResponse(BaseModel):
    users: list[LeaderboardUser]
    current_user_rank: Optional[int]
