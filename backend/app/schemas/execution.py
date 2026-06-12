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
    plots: Optional[list[str]] = []

class EvaluationRequest(BaseModel):
    challenge_id: Optional[int] = None
    lesson_id: Optional[int] = None
    code: str

class EvaluationResponse(BaseModel):
    submission_id: int
    status: str
    score: float
    test_cases_passed: int
    test_cases_total: int
    execution_time_ms: int
    test_results: list[dict]
    xp_earned: int
