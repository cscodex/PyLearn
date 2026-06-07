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
        raise HTTPException(status_code=400, detail="User is already enrolled in this course")
        
    new_enrollment = Enrollment(
        user_id=current_user.id,
        course_id=course_id,
        status="active",
        progress_percentage=0.0
    )
    
    db.add(new_enrollment)
    await db.commit()
    await db.refresh(new_enrollment)
    
    return new_enrollment
