import uuid
from typing import List, Optional, Dict, Any
from pydantic import BaseModel, ConfigDict, Field, AliasChoices
from datetime import datetime
from pydantic.alias_generators import to_camel

class CamelCaseBaseModel(BaseModel):
    model_config = ConfigDict(
        alias_generator=to_camel,
        populate_by_name=True,
        from_attributes=True
    )

class LessonBase(CamelCaseBaseModel):
    title: str
    content_type: str
    content_body: Optional[Dict[str, Any]] = None
    video_url: Optional[str] = None
    duration_minutes: Optional[int] = None
    order_index: int
    is_premium: bool = False

class LessonResponse(LessonBase):
    id: int
    chapter_id: int

class LessonCreate(LessonBase):
    pass

class LessonUpdate(CamelCaseBaseModel):
    title: Optional[str] = None
    content_type: Optional[str] = None
    content_body: Optional[Dict[str, Any]] = None
    video_url: Optional[str] = None
    duration_minutes: Optional[int] = None
    order_index: Optional[int] = None
    is_premium: Optional[bool] = None

class ChapterBase(CamelCaseBaseModel):
    title: str
    description: Optional[str] = None
    order_index: int

class ChapterCreate(ChapterBase):
    pass

class ChapterUpdate(CamelCaseBaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    order_index: Optional[int] = None

class ChapterResponse(ChapterBase):
    id: int
    module_id: int
    lessons: List[LessonResponse] = []

class ModuleBase(CamelCaseBaseModel):
    title: str
    description: Optional[str] = None
    order_index: int

class ModuleCreate(ModuleBase):
    pass

class ModuleUpdate(CamelCaseBaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    order_index: Optional[int] = None

class ModuleResponse(ModuleBase):
    id: int
    course_id: int
    chapters: List[ChapterResponse] = []

class CourseBase(CamelCaseBaseModel):
    title: str
    slug: str
    description: Optional[str] = None
    thumbnail_url: Optional[str] = None
    difficulty_level: str = Field(validation_alias=AliasChoices('difficulty', 'difficulty_level'))
    is_published: bool = False

class CourseCreate(CourseBase):
    pass

class CourseResponse(CourseBase):
    id: int
    created_at: datetime
    updated_at: datetime
    modules: List[ModuleResponse] = []

class CourseListResponse(CourseBase):
    id: int
    created_at: datetime
    updated_at: datetime

class EnrollmentBase(CamelCaseBaseModel):
    course_id: int

class EnrollmentResponse(EnrollmentBase):
    id: int
    user_id: uuid.UUID
    enrolled_at: datetime
    status: str
    progress_percentage: float

class AdminEnrollmentResponse(CamelCaseBaseModel):
    id: int
    user_id: uuid.UUID
    user_name: str
    course_id: int
    course_title: str
    enrolled_at: datetime
    status: str
    progress_percentage: float
