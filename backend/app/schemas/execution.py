from pydantic import BaseModel
from typing import Optional

class CodeExecutionRequest(BaseModel):
    code: str
    standard_input: Optional[str] = ""
    lesson_id: Optional[int] = None

class CodeExecutionResponse(BaseModel):
    stdout: str
    stderr: str
    execution_time_ms: int
    is_success: bool
    xp_earned: Optional[int] = 0
