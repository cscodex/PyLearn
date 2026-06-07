from typing import Optional, Dict, Any, List
from pydantic import Field
from .course import CamelCaseBaseModel

class QuestionOptionBase(CamelCaseBaseModel):
    option_text: str
    is_correct: bool = False
    order_index: int

class QuestionOptionCreate(QuestionOptionBase):
    pass

class QuestionOptionResponse(QuestionOptionBase):
    id: int
    question_id: int

class QuestionBase(CamelCaseBaseModel):
    question_type: str
    question_text: str
    question_data: Optional[Dict[str, Any]] = Field(default_factory=dict)
    explanation: Optional[str] = None
    difficulty: str = "medium"
    points: int = 1
    order_index: int

class QuestionCreate(QuestionBase):
    options: List[QuestionOptionCreate] = []

class QuestionResponse(QuestionBase):
    id: int
    lesson_id: int
    options: List[QuestionOptionResponse] = []

class TestCaseBase(CamelCaseBaseModel):
    input_data: str
    expected_output: str
    is_hidden: bool = False
    points: int = 1
    order_index: int

class TestCaseCreate(TestCaseBase):
    pass

class TestCaseResponse(TestCaseBase):
    id: int
    challenge_id: int

class CodingChallengeBase(CamelCaseBaseModel):
    title: str
    description: str
    difficulty: str = "easy"
    starter_code: str = ""
    solution_code: Optional[str] = None
    hints: Optional[List[str]] = None
    xp_reward: int = 20
    time_limit_seconds: int = 5
    memory_limit_mb: int = 64
    order_index: int

class CodingChallengeCreate(CodingChallengeBase):
    test_cases: List[TestCaseCreate] = []

class CodingChallengeResponse(CodingChallengeBase):
    id: int
    lesson_id: int
    test_cases: List[TestCaseResponse] = []
