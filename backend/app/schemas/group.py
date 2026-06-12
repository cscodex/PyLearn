from pydantic import BaseModel, ConfigDict
from typing import Optional, List
import uuid
from pydantic.alias_generators import to_camel
from datetime import datetime

class CamelCaseBaseModel(BaseModel):
    model_config = ConfigDict(
        alias_generator=to_camel,
        populate_by_name=True,
        from_attributes=True
    )

class GroupCreate(CamelCaseBaseModel):
    name: str

class GroupJoinRequest(CamelCaseBaseModel):
    join_code: str

class GroupResponse(CamelCaseBaseModel):
    id: int
    name: str
    creator_id: uuid.UUID
    created_at: Optional[datetime] = None
    member_count: int = 0
    join_code: Optional[str] = None

class GroupStudentCreate(CamelCaseBaseModel):
    email: str
    full_name: str
    password: str

class GroupAssignmentCreate(CamelCaseBaseModel):
    course_id: int
    assignment_type: str = "mandatory" # 'mandatory' or 'recommended'

class GroupAssignmentResponse(CamelCaseBaseModel):
    id: int
    group_id: int
    course_id: int
    assigned_by: uuid.UUID
    assignment_type: str
    created_at: datetime

class GroupUpdate(CamelCaseBaseModel):
    name: Optional[str] = None

class GroupAddStudentsBulk(CamelCaseBaseModel):
    user_ids: List[uuid.UUID]

class GroupAssignCoursesBulk(CamelCaseBaseModel):
    course_ids: List[int]
    assignment_type: str = "mandatory"
