from fastapi import APIRouter, Depends
from typing import Any
from sqlalchemy.ext.asyncio import AsyncSession

from app.api import deps
from app.models.user import User
from app.schemas.quiz import QuizSubmissionRequest, QuizSubmissionResponse

router = APIRouter()

@router.post("/submit", response_model=QuizSubmissionResponse)
async def submit_quiz(
    request: QuizSubmissionRequest,
    db: AsyncSession = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_active_user)
) -> Any:
    """Submit quiz answers and evaluate score."""
    # In a real app, we would fetch the actual correct answers from DB
    # For MVP, we'll return a mock successful response
    
    score = 100
    passed = True
    xp_earned = 20
    
    # Optional: Log progress to DB
    
    return QuizSubmissionResponse(
        score=score,
        passed=passed,
        xp_earned=xp_earned,
        feedback="Great job! You answered all questions correctly."
    )
