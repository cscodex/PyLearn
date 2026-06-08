from typing import Any, List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select

from app.api import deps
from app.models.user import User
from app.models.course import Course, Module, Chapter, Lesson
from app.models.assessment import Question, QuestionOption, CodingChallenge, TestCase
from app.schemas.course import CourseCreate, CourseResponse, CourseListResponse, ModuleCreate, ModuleResponse, ChapterCreate, ChapterResponse, LessonCreate, LessonResponse
from app.schemas.assessment import QuestionCreate, QuestionResponse, CodingChallengeCreate, CodingChallengeResponse

router = APIRouter()


@router.get("/courses", response_model=List[CourseListResponse])
async def list_creator_courses(
    skip: int = 0,
    limit: int = 100,
    db: AsyncSession = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_creator_user)
) -> Any:
    """
    Retrieve courses. Admins see all, creators see their own.
    """
    query = select(Course)
    if current_user.role != "admin":
        query = query.filter(Course.instructor_id == current_user.id)
    
    result = await db.execute(query.offset(skip).limit(limit))
    return result.scalars().all()

@router.post("/courses", response_model=CourseResponse)
async def create_course(
    *,
    db: AsyncSession = Depends(deps.get_db),
    course_in: CourseCreate,
    current_user: User = Depends(deps.get_current_creator_user)
) -> Any:
    """Create new course."""
    course = Course(
        title=course_in.title,
        slug=course_in.slug,
        description=course_in.description,
        thumbnail_url=course_in.thumbnail_url,
        difficulty=course_in.difficulty_level,
        is_published=course_in.is_published,
        instructor_id=current_user.id
    )
    db.add(course)
    await db.commit()
    await db.refresh(course)
    return {
        "id": course.id,
        "title": course.title,
        "slug": course.slug,
        "description": course.description,
        "thumbnail_url": course.thumbnail_url,
        "difficulty_level": course.difficulty,
        "is_published": course.is_published,
        "created_at": course.created_at,
        "updated_at": course.updated_at,
        "modules": []
    }

@router.post("/courses/{course_id}/modules", response_model=ModuleResponse)
async def create_module(
    *,
    db: AsyncSession = Depends(deps.get_db),
    course_id: int,
    module_in: ModuleCreate,
    current_user: User = Depends(deps.get_current_creator_user)
) -> Any:
    """Create new module for a course."""
    # Verify course ownership
    result = await db.execute(select(Course).filter(Course.id == course_id, Course.instructor_id == current_user.id))
    if not result.scalars().first() and current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Not authorized to edit this course")
        
    module = Module(
        course_id=course_id,
        title=module_in.title,
        description=module_in.description,
        order_index=module_in.order_index
    )
    db.add(module)
    await db.commit()
    await db.refresh(module)
    return {
        "id": module.id,
        "course_id": module.course_id,
        "title": module.title,
        "description": module.description,
        "order_index": module.order_index,
        "chapters": []
    }

@router.post("/modules/{module_id}/chapters", response_model=ChapterResponse)
async def create_chapter(
    *,
    db: AsyncSession = Depends(deps.get_db),
    module_id: int,
    chapter_in: ChapterCreate,
    current_user: User = Depends(deps.get_current_creator_user)
) -> Any:
    """Create new chapter for a module."""
    chapter = Chapter(
        module_id=module_id,
        title=chapter_in.title,
        description=chapter_in.description,
        order_index=chapter_in.order_index
    )
    db.add(chapter)
    await db.commit()
    await db.refresh(chapter)
    return {
        "id": chapter.id,
        "module_id": chapter.module_id,
        "title": chapter.title,
        "description": chapter.description,
        "order_index": chapter.order_index,
        "lessons": []
    }

@router.post("/chapters/{chapter_id}/lessons", response_model=LessonResponse)
async def create_lesson(
    *,
    db: AsyncSession = Depends(deps.get_db),
    chapter_id: int,
    lesson_in: LessonCreate,
    current_user: User = Depends(deps.get_current_creator_user)
) -> Any:
    """Create new lesson for a chapter."""
    lesson = Lesson(
        chapter_id=chapter_id,
        title=lesson_in.title,
        content_type=lesson_in.content_type,
        content_body=lesson_in.content_body,
        video_url=lesson_in.video_url,
        duration_minutes=lesson_in.duration_minutes,
        order_index=lesson_in.order_index,
        is_free_preview=lesson_in.is_premium == False
    )
    db.add(lesson)
    await db.commit()
    await db.refresh(lesson)
    return {
        "id": lesson.id,
        "chapter_id": lesson.chapter_id,
        "title": lesson.title,
        "content_type": lesson.content_type,
        "content_body": lesson.content_body,
        "video_url": lesson.video_url,
        "duration_minutes": lesson.duration_minutes,
        "order_index": lesson.order_index,
        "is_premium": not lesson.is_free_preview
    }

@router.post("/lessons/{lesson_id}/questions", response_model=QuestionResponse)
async def create_question(
    *,
    db: AsyncSession = Depends(deps.get_db),
    lesson_id: int,
    question_in: QuestionCreate,
    current_user: User = Depends(deps.get_current_creator_user)
) -> Any:
    """Create new quiz question for a lesson."""
    question = Question(
        lesson_id=lesson_id,
        question_type=question_in.question_type,
        question_text=question_in.question_text,
        question_data=question_in.question_data,
        explanation=question_in.explanation,
        difficulty=question_in.difficulty,
        points=question_in.points,
        order_index=question_in.order_index
    )
    db.add(question)
    await db.commit()
    await db.refresh(question)
    
    options_data = []
    for opt_in in question_in.options:
        opt = QuestionOption(
            question_id=question.id,
            option_text=opt_in.option_text,
            is_correct=opt_in.is_correct,
            order_index=opt_in.order_index
        )
        db.add(opt)
        options_data.append(opt)
    
    await db.commit()
    await db.refresh(question)
    for opt in options_data:
        await db.refresh(opt)
        
    return {
        "id": question.id,
        "lesson_id": question.lesson_id,
        "question_type": question.question_type,
        "question_text": question.question_text,
        "question_data": question.question_data,
        "explanation": question.explanation,
        "difficulty": question.difficulty,
        "points": question.points,
        "order_index": question.order_index,
        "options": [
            {
                "id": opt.id,
                "question_id": opt.question_id,
                "option_text": opt.option_text,
                "is_correct": opt.is_correct,
                "order_index": opt.order_index
            } for opt in options_data
        ]
    }

@router.post("/lessons/{lesson_id}/challenges", response_model=CodingChallengeResponse)
async def create_coding_challenge(
    *,
    db: AsyncSession = Depends(deps.get_db),
    lesson_id: int,
    challenge_in: CodingChallengeCreate,
    current_user: User = Depends(deps.get_current_creator_user)
) -> Any:
    """Create new coding challenge for a lesson."""
    challenge = CodingChallenge(
        lesson_id=lesson_id,
        title=challenge_in.title,
        description=challenge_in.description,
        difficulty=challenge_in.difficulty,
        starter_code=challenge_in.starter_code,
        solution_code=challenge_in.solution_code,
        hints=challenge_in.hints,
        xp_reward=challenge_in.xp_reward,
        time_limit_seconds=challenge_in.time_limit_seconds,
        memory_limit_mb=challenge_in.memory_limit_mb,
        order_index=challenge_in.order_index
    )
    db.add(challenge)
    await db.commit()
    await db.refresh(challenge)
    
    test_cases_data = []
    for tc_in in challenge_in.test_cases:
        tc = TestCase(
            challenge_id=challenge.id,
            input_data=tc_in.input_data,
            expected_output=tc_in.expected_output,
            is_hidden=tc_in.is_hidden,
            points=tc_in.points,
            order_index=tc_in.order_index
        )
        db.add(tc)
        test_cases_data.append(tc)
        
    await db.commit()
    for tc in test_cases_data:
        await db.refresh(tc)
        
    return {
        "id": challenge.id,
        "lesson_id": challenge.lesson_id,
        "title": challenge.title,
        "description": challenge.description,
        "difficulty": challenge.difficulty,
        "starter_code": challenge.starter_code,
        "solution_code": challenge.solution_code,
        "hints": challenge.hints,
        "xp_reward": challenge.xp_reward,
        "time_limit_seconds": challenge.time_limit_seconds,
        "memory_limit_mb": challenge.memory_limit_mb,
        "order_index": challenge.order_index,
        "test_cases": [
            {
                "id": tc.id,
                "challenge_id": tc.challenge_id,
                "input_data": tc.input_data,
                "expected_output": tc.expected_output,
                "is_hidden": tc.is_hidden,
                "points": tc.points,
                "order_index": tc.order_index
            } for tc in test_cases_data
        ]
    }

from app.models.progress import Enrollment
from app.schemas.course import AdminEnrollmentResponse

@router.get("/enrollments", response_model=List[AdminEnrollmentResponse])
async def list_creator_enrollments(
    skip: int = 0,
    limit: int = 100,
    db: AsyncSession = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_creator_user)
) -> Any:
    """
    Retrieve all enrollments for courses created by the current creator.
    """
    result = await db.execute(
        select(Enrollment, User.full_name, Course.title)
        .join(User, User.id == Enrollment.user_id)
        .join(Course, Course.id == Enrollment.course_id)
        .filter(Course.instructor_id == current_user.id)
        .offset(skip).limit(limit)
    )
    
    rows = result.all()
    response = []
    for row in rows:
        enrollment, user_name, course_title = row
        response.append(AdminEnrollmentResponse(
            id=enrollment.id,
            user_id=enrollment.user_id,
            user_name=user_name,
            course_id=enrollment.course_id,
            course_title=course_title,
            enrolled_at=enrollment.enrolled_at,
            status=enrollment.status,
            progress_percentage=float(enrollment.progress_percentage)
        ))
        
    return response

@router.put("/courses/{course_id}", response_model=CourseResponse)
async def update_course(
    *,
    db: AsyncSession = Depends(deps.get_db),
    course_id: int,
    course_in: CourseCreate,
    current_user: User = Depends(deps.get_current_creator_user)
) -> Any:
    """Update a course."""
    result = await db.execute(select(Course).filter(Course.id == course_id))
    course = result.scalars().first()
    if not course:
        raise HTTPException(status_code=404, detail="Course not found")
    if course.instructor_id != current_user.id and current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Not authorized to edit this course")
        
    course.title = course_in.title
    course.slug = course_in.slug
    course.description = course_in.description
    course.thumbnail_url = course_in.thumbnail_url
    course.difficulty = course_in.difficulty_level
    course.is_published = course_in.is_published
    
    await db.commit()
    await db.refresh(course)
    
    return {
        "id": course.id,
        "title": course.title,
        "slug": course.slug,
        "description": course.description,
        "thumbnail_url": course.thumbnail_url,
        "difficulty_level": course.difficulty,
        "is_published": course.is_published,
        "created_at": course.created_at,
        "updated_at": course.updated_at,
        "modules": []
    }
