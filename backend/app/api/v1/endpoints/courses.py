from typing import Any, List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy.orm import selectinload

from app.api import deps
from app.models.course import Course, Module, Chapter
from app.models.progress import Enrollment
from app.models.user import User
from app.schemas.course import CourseResponse, CourseListResponse, EnrollmentResponse

router = APIRouter()

@router.get("/", response_model=List[CourseListResponse])
async def get_courses(
    db: AsyncSession = Depends(deps.get_db),
    skip: int = 0,
    limit: int = 100,
) -> Any:
    """Retrieve all published courses."""
    result = await db.execute(
        select(Course)
        .filter(Course.is_published == True)
        .offset(skip)
        .limit(limit)
    )
    courses = result.scalars().all()
    return courses

@router.get("/enrolled", response_model=List[CourseListResponse])
async def get_enrolled_courses(
    db: AsyncSession = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_active_user)
) -> Any:
    """Retrieve courses the current user is enrolled in."""
    result = await db.execute(
        select(Course)
        .join(Enrollment, Enrollment.course_id == Course.id)
        .filter(Enrollment.user_id == current_user.id)
    )
    courses = result.scalars().all()
    return courses

@router.get("/recommended", response_model=List[CourseListResponse])
async def get_recommended_courses(
    db: AsyncSession = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_active_user)
) -> Any:
    """Retrieve courses recommended for the user via GroupAssignments."""
    from app.models.group import GroupAssignment, GroupMember
    result = await db.execute(
        select(Course)
        .join(GroupAssignment, GroupAssignment.course_id == Course.id)
        .join(GroupMember, GroupMember.group_id == GroupAssignment.group_id)
        .filter(GroupMember.user_id == current_user.id)
        .filter(GroupAssignment.assignment_type == "recommended")
    )
    courses = result.scalars().all()
    # Deduplicate in case of multiple groups recommending the same course
    unique_courses = list({c.id: c for c in courses}.values())
    return unique_courses

@router.get("/{course_id}", response_model=CourseResponse)
async def get_course(
    course_id: int,
    db: AsyncSession = Depends(deps.get_db),
) -> Any:
    """Retrieve course by ID with all modules, chapters, and lessons."""
    result = await db.execute(
        select(Course)
        .options(
            selectinload(Course.modules)
            .selectinload(Module.chapters)
            .selectinload(Chapter.lessons)
        )
        .filter(Course.id == course_id)
    )
    course = result.scalars().first()
    if not course:
        raise HTTPException(status_code=404, detail="Course not found")
    return course

@router.post("/{course_id}/enroll", response_model=EnrollmentResponse)
async def enroll_course(
    course_id: int,
    db: AsyncSession = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_active_user)
) -> Any:
    """Enroll the current user in a specific course."""
    # Check if course exists
    result = await db.execute(select(Course).filter(Course.id == course_id))
    course = result.scalars().first()
    if not course:
        raise HTTPException(status_code=404, detail="Course not found")
        
    # Check if already enrolled
    result = await db.execute(
        select(Enrollment)
        .filter(Enrollment.user_id == current_user.id)
        .filter(Enrollment.course_id == course_id)
    )
    enrollment = result.scalars().first()
    
    if enrollment:
        # Already enrolled, return 200 OK with the existing enrollment data
        # so the frontend can seamlessly continue.
        return {
            "id": enrollment.id,
            "course_id": enrollment.course_id,
            "user_id": enrollment.user_id,
            "enrolled_at": enrollment.enrolled_at,
            "status": "active",
            "progress_percentage": enrollment.progress_percentage
        }
        
    new_enrollment = Enrollment(
        user_id=current_user.id,
        course_id=course_id,
        progress_percentage=0
    )
    
    db.add(new_enrollment)
    await db.commit()
    await db.refresh(new_enrollment)
    
    return {
        "id": new_enrollment.id,
        "course_id": new_enrollment.course_id,
        "user_id": new_enrollment.user_id,
        "enrolled_at": new_enrollment.enrolled_at,
        "status": "in_progress",
        "progress_percentage": 0.0
    }

@router.get("/{course_id}/progress")
async def get_course_progress(
    course_id: int,
    db: AsyncSession = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_active_user)
) -> Any:
    """Get the current user's progress for a specific course."""
    from app.models.progress import UserLessonProgress, Enrollment
    
    # Check enrollment
    enrollment = await db.execute(
        select(Enrollment).filter_by(user_id=current_user.id, course_id=course_id)
    )
    enrollment = enrollment.scalars().first()
    
    if not enrollment:
        return {"completed_lesson_ids": [], "progress_percentage": 0.0}
        
    # Get all completed lessons
    progress_records = await db.execute(
        select(UserLessonProgress)
        .filter_by(user_id=current_user.id, enrollment_id=enrollment.id, status="completed")
    )
    completed_lesson_ids = [p.lesson_id for p in progress_records.scalars().all()]
    
    return {
        "completed_lesson_ids": completed_lesson_ids,
        "progress_percentage": enrollment.progress_percentage or 0.0
    }

@router.post("/{course_id}/lessons/{lesson_id}/complete")
async def complete_lesson(
    course_id: int,
    lesson_id: int,
    db: AsyncSession = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_active_user)
) -> Any:
    """Mark a lesson as complete and update course progress."""
    from app.models.progress import UserLessonProgress, Enrollment
    from app.models.course import Course, Module, Chapter, Lesson
    from sqlalchemy import func
    import datetime
    
    # Check enrollment
    enrollment = await db.execute(
        select(Enrollment).filter_by(user_id=current_user.id, course_id=course_id)
    )
    enrollment = enrollment.scalars().first()
    
    if not enrollment:
        raise HTTPException(status_code=400, detail="Not enrolled in this course")
        
    # Check if progress record exists
    progress_result = await db.execute(
        select(UserLessonProgress)
        .filter_by(user_id=current_user.id, lesson_id=lesson_id, enrollment_id=enrollment.id)
    )
    progress = progress_result.scalars().first()
    
    if progress:
        if progress.status != "completed":
            progress.status = "completed"
            progress.completed_at = datetime.datetime.now(datetime.timezone.utc)
    else:
        progress = UserLessonProgress(
            user_id=current_user.id,
            lesson_id=lesson_id,
            enrollment_id=enrollment.id,
            status="completed",
            completed_at=datetime.datetime.now(datetime.timezone.utc)
        )
        db.add(progress)
        
    # Calculate new progress percentage
    # Count total lessons in course
    total_lessons_result = await db.execute(
        select(func.count(Lesson.id))
        .join(Chapter, Lesson.chapter_id == Chapter.id)
        .join(Module, Chapter.module_id == Module.id)
        .filter(Module.course_id == course_id)
    )
    total_lessons = total_lessons_result.scalar() or 1
    
    # Count completed lessons for user
    completed_lessons_result = await db.execute(
        select(func.count(UserLessonProgress.id))
        .filter_by(user_id=current_user.id, enrollment_id=enrollment.id, status="completed")
    )
    # +1 to include the one we just completed if it wasn't already in DB
    completed_lessons = completed_lessons_result.scalar() or 0
    if not progress.id: # If new, it won't be counted in the query yet since not committed
        completed_lessons += 1
        
    percentage = min(100.0, (completed_lessons / total_lessons) * 100.0)
    enrollment.progress_percentage = percentage
    
    await db.commit()
    
    return {"success": True, "progress_percentage": percentage}

