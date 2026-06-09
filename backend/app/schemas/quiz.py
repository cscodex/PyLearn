from pydantic import BaseModel
from typing import List, Optional

class QuestionOptionResponse(BaseModel):
    id: int
    option_text: str

class QuestionResponse(BaseModel):
    id: int
    question_text: str
    question_type: str
    options: List[QuestionOptionResponse]

class QuizFetchResponse(BaseModel):
    lesson_id: int
    questions: List[QuestionResponse]
    previous_submission: Optional[dict] = None

class QuizSubmissionRequest(BaseModel):
    lesson_id: int
    answers: dict[int, int]  # question_id -> option_id

class QuizSubmissionResponse(BaseModel):
    score: int
    passed: bool
    xp_earned: int
    feedback: Optional[str] = None
