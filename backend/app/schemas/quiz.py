from pydantic import BaseModel
from typing import List, Optional

class QuizSubmissionRequest(BaseModel):
    lesson_id: int
    answers: dict[str, str]  # question_id -> selected_option

class QuizSubmissionResponse(BaseModel):
    score: int
    passed: bool
    xp_earned: int
    feedback: Optional[str] = None
