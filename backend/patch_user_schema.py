import re

with open("app/schemas/user.py", "r") as f:
    content = f.read()

new_schemas = """
class UserAchievementResponse(CamelCaseBaseModel):
    id: str
    title: str
    description: str
    icon_url: Optional[str]
    unlocked_at: str

class UserHistoryResponse(CamelCaseBaseModel):
    course_id: int
    course_title: str
    progress_percentage: float
    last_accessed_at: Optional[str] = None
    completed_at: Optional[str] = None
"""

content = content + new_schemas

with open("app/schemas/user.py", "w") as f:
    f.write(content)
