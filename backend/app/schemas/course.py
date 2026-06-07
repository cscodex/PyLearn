import uuid
from typing import List, Optional, Dict, Any
from pydantic import BaseModel
from datetime import datetime

class LessonBase(BaseModel):
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

    class Config:
        from_attributes = True

class ChapterBase(BaseModel):
    title: str
    description: Optional[str] = None
    order_index: int

class ChapterResponse(ChapterBase):
    id: int
    module_id: int
    lessons: List[LessonResponse] = []

    class Config:
        from_attributes = True

class ModuleBase(BaseModel):
    title: str
    description: Optional[str] = None
    order_index: int

class ModuleResponse(ModuleBase):
    id: int
    course_id: int
    chapters: List[ChapterResponse] = []

    class Config:
        from_attributes = True

class CourseBase(BaseModel):
    title: str
    slug: str
    description: Optional[str] = None
    thumbnail_url: Optional[str] = None
    difficulty_level: str
    is_published: bool = False

class CourseResponse(CourseBase):
    id: int
    created_at: datetime
    updated_at: datetime
    modules: List[ModuleResponse] = []

    class Config:
        from_attributes = True

class CourseListResponse(CourseBase):
    id: int
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

class EnrollmentBase(BaseModel):
    course_id: int

class EnrollmentResponse(EnrollmentBase):
    id: int
    user_id: uuid.UUID
    enrolled_at: datetime
    status: str
    progress_percentage: float

    class Config:
        from_attributes = True
