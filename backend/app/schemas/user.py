from pydantic import BaseModel, ConfigDict
from typing import Optional
from pydantic.alias_generators import to_camel

class CamelCaseBaseModel(BaseModel):
    model_config = ConfigDict(
        alias_generator=to_camel,
        populate_by_name=True,
        from_attributes=True
    )

class UserStatsResponse(CamelCaseBaseModel):
    id: int
    full_name: str
    email: str
    xp: int
    streak_days: int
    profile_picture_url: Optional[str]

class LeaderboardUser(CamelCaseBaseModel):
    id: int
    full_name: str
    xp: int
    profile_picture_url: Optional[str]
    rank: int

class LeaderboardResponse(CamelCaseBaseModel):
    users: list[LeaderboardUser]
    current_user_rank: Optional[int]
