from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime

class SavedProgramBase(BaseModel):
    title: str = Field(..., max_length=100)
    code: str = Field(..., max_length=65536) # 64KB
    language: Optional[str] = "python"
    lesson_id: Optional[int] = None

class SavedProgramCreate(SavedProgramBase):
    pass

class SavedProgramUpdate(BaseModel):
    title: Optional[str] = Field(None, max_length=100)
    code: Optional[str] = Field(None, max_length=65536)
    language: Optional[str] = None

class SavedProgramInDBBase(SavedProgramBase):
    id: int
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True

class SavedProgram(SavedProgramInDBBase):
    pass

class StudentProgramSchema(SavedProgram):
    student_name: str
    student_email: str
