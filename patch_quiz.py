import sys

content = open("backend/app/schemas/quiz.py").read()

if "previous_submission: Optional[dict] = None" not in content:
    content = content.replace(
        "questions: List[QuestionResponse]",
        "questions: List[QuestionResponse]\n    previous_submission: Optional[dict] = None"
    )
    with open("backend/app/schemas/quiz.py", "w") as f:
        f.write(content)
        
content2 = open("backend/app/api/v1/endpoints/quiz.py").read()
if "previous_submission" not in content2:
    new_get = """
@router.get("/{lesson_id}", response_model=QuizFetchResponse)
async def get_quiz(
    lesson_id: int,
    db: AsyncSession = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_active_user)
) -> Any:
    \"\"\"Fetch all questions for a given lesson without revealing correct answers.\"\"\"
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
            for s in subs:
                if s.answer_data and "selected_option_id" in s.answer_data:
                    answers[str(s.question_id)] = s.answer_data["selected_option_id"]
                score += (s.score or 0)
            
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
"""
    import re
    content2 = re.sub(
        r'@router\.get\("/\{lesson_id\}", response_model=QuizFetchResponse\).*?return QuizFetchResponse\(lesson_id=lesson_id, questions=question_responses\)',
        new_get.strip(),
        content2,
        flags=re.DOTALL
    )
    with open("backend/app/api/v1/endpoints/quiz.py", "w") as f:
        f.write(content2)

print("Patched schemas/quiz.py and endpoints/quiz.py")
