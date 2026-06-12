from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File, Form
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.models.group import GroupMember
from typing import Any, List, Dict
import pandas as pd
import io
import uuid
import secrets
import string
from app.api import deps
from app.models.user import User, UserProfile
from app.core.security import get_password_hash

router = APIRouter()

def generate_password(length=10):
    alphabet = string.ascii_letters + string.digits
    return ''.join(secrets.choice(alphabet) for i in range(length))

@router.post("/import-students")
async def import_students(
    file: UploadFile = File(...),
    group_id: int = Form(None),
    db: AsyncSession = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_active_user)
) -> Any:
    """Import students from CSV and auto-generate passwords."""
    if current_user.role not in ["admin", "creator"]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not enough permissions"
        )
    
    if not file.filename.endswith('.csv'):
        raise HTTPException(status_code=400, detail="File must be a CSV")
        
    content = await file.read()
    try:
        df = pd.read_csv(io.StringIO(content.decode('utf-8')))
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Failed to parse CSV: {str(e)}")
        
    required_cols = ['email', 'full_name', 'class_section']
    for col in required_cols:
        if col not in df.columns:
            raise HTTPException(status_code=400, detail=f"Missing required column: {col}")
            
    imported_users = []
    
    for _, row in df.iterrows():
        email = str(row['email']).strip().lower()
        full_name = str(row['full_name']).strip()
        class_section = str(row['class_section']).strip()
        
        # Check if user exists
        stmt = select(User).where(User.email == email)
        result = await db.execute(stmt)
        if result.scalar_one_or_none():
            continue # Skip existing users for now
            
        password = generate_password()
        hashed_pw = get_password_hash(password)
        
        new_user = User(
            email=email,
            full_name=full_name,
            password_hash=hashed_pw,
            role="student",
            is_active=True
        )
        db.add(new_user)
        await db.commit()
        await db.refresh(new_user)
        
        new_profile = UserProfile(
            user_id=new_user.id,
            class_section=class_section
        )
        db.add(new_profile)
        await db.commit()
        
        imported_users.append({
            "email": email,
            "full_name": full_name,
            "password": password,
            "class_section": class_section
        })
        
        if group_id:
            db.add(GroupMember(group_id=group_id, user_id=new_user.id))
            await db.commit()
        
    return {"message": f"Successfully imported {len(imported_users)} students", "users": imported_users}

from app.models.assessment import CodeSubmission, CodingChallenge

@router.get("/student-submissions")
async def get_student_submissions(
    db: AsyncSession = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_active_user)
) -> Any:
    """Get all code submissions for grading/review."""
    if current_user.role not in ["admin", "creator"]:
        raise HTTPException(status_code=403, detail="Not enough permissions")
        
    stmt = (
        select(CodeSubmission, User.full_name, CodingChallenge.title)
        .join(User, User.id == CodeSubmission.user_id)
        .join(CodingChallenge, CodingChallenge.id == CodeSubmission.challenge_id)
        .order_by(CodeSubmission.submitted_at.desc())
    )
    result = await db.execute(stmt)
    rows = result.all()
    
    submissions = []
    for sub, student_name, chal_title in rows:
        submissions.append({
            "id": sub.id,
            "student_name": student_name,
            "challenge_title": chal_title,
            "status": sub.status,
            "score": float(sub.score),
            "test_cases_passed": sub.test_cases_passed,
            "test_cases_total": sub.test_cases_total,
            "submitted_at": sub.submitted_at.isoformat() if sub.submitted_at else None,
            "source_code": sub.source_code,
            "test_results": sub.test_results
        })
        
    return submissions
