from fastapi import APIRouter, Depends, HTTPException
from typing import Any
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from sqlalchemy.orm import selectinload

from app.api import deps
from app.models.user import User
from app.models.assessment import Question, QuestionOption, QuizSubmission
from app.schemas.quiz import (
    QuizSubmissionRequest, 
    QuizSubmissionResponse,
    QuizFetchResponse,
    QuestionResponse,
    QuestionOptionResponse
)

router = APIRouter()

@router.get("/{lesson_id}", response_model=QuizFetchResponse)
async def get_quiz(
    lesson_id: int,
    db: AsyncSession = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_active_user)
) -> Any:
    """Fetch all questions for a given lesson without revealing correct answers."""
    result = await db.execute(
        select(Question)
        .where(Question.lesson_id == lesson_id)
        .options(selectinload(Question.options))
        .order_by(Question.order_index)
    )
    questions = result.scalars().all()
    
    if not questions:
        raise HTTPException(status_code=404, detail="No quiz found for this lesson")

    question_responses = []
    question_ids = []
    for q in questions:
        question_ids.append(q.id)
        options = [
            QuestionOptionResponse(id=opt.id, option_text=opt.option_text)
            for opt in q.options
        ]
        question_responses.append(
            QuestionResponse(
                id=q.id,
                question_text=q.question_text,
                question_type=q.question_type,
                options=options
            )
        )

    # Check for previous submissions
    previous_submission = None
    if question_ids:
        sub_result = await db.execute(
            select(QuizSubmission)
            .where(QuizSubmission.user_id == current_user.id)
            .where(QuizSubmission.question_id.in_(question_ids))
        )
        subs = sub_result.scalars().all()
        if subs:
            # Reconstruct submission data
            answers = {}
            score = 0
            
            # Sort subs by submitted_at desc to get latest
            subs.sort(key=lambda x: x.submitted_at, reverse=True)
            seen_questions = set()
            
            for s in subs:
                if s.question_id in seen_questions:
                    continue
                seen_questions.add(s.question_id)
                if s.answer_data and "selected_option_id" in s.answer_data:
                    answers[str(s.question_id)] = s.answer_data["selected_option_id"]
                score += float(s.score or 0)
            
            # total possible points
            total_pts = sum(q.points for q in questions)
            percentage = int((score / total_pts) * 100) if total_pts > 0 else 0
            
            previous_submission = {
                "answers": answers,
                "score": percentage,
                "passed": percentage >= 70
            }

    return QuizFetchResponse(
        lesson_id=lesson_id, 
        questions=question_responses,
        previous_submission=previous_submission
    )


@router.post("/submit", response_model=QuizSubmissionResponse)
async def submit_quiz(
    request: QuizSubmissionRequest,
    db: AsyncSession = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_active_user)
) -> Any:
    """Submit quiz answers and evaluate score."""
    result = await db.execute(
        select(Question)
        .where(Question.lesson_id == request.lesson_id)
        .options(selectinload(Question.options))
    )
    questions = result.scalars().all()
    
    if not questions:
        raise HTTPException(status_code=404, detail="Quiz not found")

    total_possible_points = 0
    earned_points = 0
    total_xp_awarded_this_time = 0

    # Fetch previous submissions to prevent double-dipping XP
    question_ids = [q.id for q in questions]
    prev_subs_result = await db.execute(
        select(QuizSubmission)
        .where(QuizSubmission.user_id == current_user.id)
        .where(QuizSubmission.question_id.in_(question_ids))
    )
    prev_subs = prev_subs_result.scalars().all()
    answered_correctly = set(s.question_id for s in prev_subs if s.is_correct)

    for q in questions:
        total_possible_points += q.points
        user_answer_id = request.answers.get(q.id)
        
        is_correct = False
        if user_answer_id is not None:
            # Check if option is correct
            for opt in q.options:
                if opt.id == user_answer_id and opt.is_correct:
                    is_correct = True
                    earned_points += q.points
                    break
        
        # Calculate XP to award
        question_xp = q.points * 5 if is_correct else 0
        new_xp_to_award = 0
        if is_correct and q.id not in answered_correctly:
            new_xp_to_award = question_xp
            total_xp_awarded_this_time += new_xp_to_award
        
        # Save submission for each question
        submission = QuizSubmission(
            user_id=current_user.id,
            question_id=q.id,
            answer_data={"selected_option_id": user_answer_id},
            is_correct=is_correct,
            score=q.points if is_correct else 0,
            xp_earned=new_xp_to_award
        )
        db.add(submission)

    # Calculate final score out of 100
    score = int((earned_points / total_possible_points) * 100) if total_possible_points > 0 else 0
    passed = score >= 70

    # Add XP to user
    current_user.xp += total_xp_awarded_this_time
    
    await db.commit()

    feedback = f"You scored {score}%!"
    if passed:
        feedback += " Great job!"
    else:
        feedback += " Keep practicing and try again."

    return QuizSubmissionResponse(
        score=score,
        passed=passed,
        xp_earned=total_xp_awarded_this_time,
        feedback=feedback
    )
