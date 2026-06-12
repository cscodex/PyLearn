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
    from app.models.course import Course, Module, Chapter, Lesson
    from sqlalchemy import func
    
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
    
    # Dynamically recount total lessons just in case the creator added more
    total_lessons_result = await db.execute(
        select(func.count(Lesson.id))
        .join(Chapter, Lesson.chapter_id == Chapter.id)
        .join(Module, Chapter.module_id == Module.id)
        .filter(Module.course_id == course_id)
    )
    total_lessons = total_lessons_result.scalar() or 1
    
    # Recalculate percentage
    computed_percentage = min(100.0, (len(completed_lesson_ids) / total_lessons) * 100.0)
    
    # Update enrollment if it drifted
    if abs((enrollment.progress_percentage or 0.0) - computed_percentage) > 0.01:
        enrollment.progress_percentage = computed_percentage
        await db.commit()

    return {
        "completed_lesson_ids": completed_lesson_ids,
        "progress_percentage": computed_percentage
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
    from app.models.user import User
    from app.models.assessment import Question, QuizSubmission
    from sqlalchemy import func, cast, Integer
    import datetime
    
    # Check enrollment
    enrollment = await db.execute(
        select(Enrollment).filter_by(user_id=current_user.id, course_id=course_id)
    )
    enrollment = enrollment.scalars().first()
    
    if not enrollment:
        # Auto-enroll the user if they aren't enrolled yet but are marking a lesson complete
        enrollment = Enrollment(
            user_id=current_user.id,
            course_id=course_id,
            progress_percentage=0.0
        )
        db.add(enrollment)
        await db.commit()
        await db.refresh(enrollment)
        
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
    
    if percentage >= 100.0:
        if not enrollment.completed_at:
            enrollment.completed_at = datetime.datetime.now(datetime.timezone.utc)
            
        # Check if certificate exists
        from app.models.misc import Certificate
        cert_result = await db.execute(select(Certificate).filter_by(user_id=current_user.id, course_id=course_id))
        cert = cert_result.scalars().first()
        
        if not cert:
            from app.services.certificate_service import generate_and_upload_certificate
            import uuid
            
            # Get course with creator
            course_result = await db.execute(select(Course).filter_by(id=course_id))
            course = course_result.scalars().first()
            
            # Get instructor name
            instructor_name = "Instructor"
            if course and course.instructor_id:
                instructor_result = await db.execute(select(User).filter_by(id=course.instructor_id))
                instructor = instructor_result.scalars().first()
                if instructor:
                    instructor_name = instructor.full_name
            
            # Get director/admin name
            admin_result = await db.execute(select(User).filter_by(role="admin").order_by(User.id).limit(1))
            admin = admin_result.scalars().first()
            director_name = admin.full_name if admin else "Director"
            
            # Get Course Duration
            duration_str = "40 Hours"
            if course and course.estimated_hours:
                hours = int(course.estimated_hours)
                duration_str = f"{hours} Hours"
                
            # Get Lesson Concepts (up to 6)
            lessons_result = await db.execute(
                select(Lesson.title)
                .join(Chapter, Lesson.chapter_id == Chapter.id)
                .join(Module, Chapter.module_id == Module.id)
                .filter(Module.course_id == course_id)
                .order_by(Module.order_index, Chapter.order_index, Lesson.order_index)
                .limit(6)
            )
            concepts = [title for title in lessons_result.scalars().all()]
            
            # Calculate Score and Grade
            score_result = await db.execute(
                select(func.avg(cast(QuizSubmission.is_correct, Integer)))
                .join(Question, QuizSubmission.question_id == Question.id)
                .join(Lesson, Question.lesson_id == Lesson.id)
                .join(Chapter, Lesson.chapter_id == Chapter.id)
                .join(Module, Chapter.module_id == Module.id)
                .filter(Module.course_id == course_id)
                .filter(QuizSubmission.user_id == current_user.id)
            )
            avg_score = score_result.scalar()
            
            score_str = "Completed"
            grade_str = "-"
            
            if avg_score is not None:
                score_pct = float(avg_score) * 100.0
                score_str = f"{int(score_pct)}%"
                
                if score_pct >= 90:
                    grade_str = "A+"
                elif score_pct >= 80:
                    grade_str = "A"
                elif score_pct >= 70:
                    grade_str = "B"
                elif score_pct >= 60:
                    grade_str = "C"
                else:
                    grade_str = "D"

            cert_id_str = str(uuid.uuid4())[:8].upper()
            
            # This should ideally be a background task to avoid blocking the request,
            # but for now we do it synchronously to ensure it's available immediately.
            secure_url = generate_and_upload_certificate(
                student_name=current_user.full_name,
                course_name=course.title if course else "Course",
                certificate_id=cert_id_str,
                instructor_name=instructor_name,
                director_name=director_name,
                duration_str=duration_str,
                score_str=score_str,
                grade_str=grade_str,
                concepts=concepts
            )
            
            new_cert = Certificate(
                user_id=current_user.id,
                course_id=course_id,
                certificate_number=cert_id_str,
                pdf_url=secure_url
            )
            db.add(new_cert)

    await db.commit()
    
    return {"success": True, "progress_percentage": percentage}

