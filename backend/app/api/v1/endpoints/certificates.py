from typing import Any, List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select

from app.api import deps
from app.models.user import User
from app.models.misc import Certificate
from pydantic import BaseModel
import datetime

router = APIRouter()

class CertificateSchema(BaseModel):
    id: str
    certificate_number: str
    course_name: str
    pdf_url: str
    issued_at: datetime.datetime
    student_name: str

    class Config:
        from_attributes = True

@router.get("/me", response_model=List[CertificateSchema])
async def get_my_certificates(
    db: AsyncSession = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_active_user)
) -> Any:
    """Get all certificates for the current user."""
    from app.models.course import Course
    stmt = (
        select(Certificate, Course.title)
        .join(Course, Certificate.course_id == Course.id)
        .where(Certificate.user_id == current_user.id)
        .order_by(Certificate.issued_at.desc())
    )
    result = await db.execute(stmt)
    
    certs = []
    for cert, course_title in result.all():
        certs.append({
            "id": str(cert.id),
            "certificate_number": cert.certificate_number,
            "course_name": course_title,
            "pdf_url": cert.pdf_url,
            "issued_at": cert.issued_at,
            "student_name": current_user.full_name
        })
    return certs

@router.get("/all", response_model=List[CertificateSchema])
async def get_all_certificates(
    db: AsyncSession = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_active_user)
) -> Any:
    """Get all certificates across the platform. (Admin/Creator only)"""
    if current_user.role not in ["admin", "creator"]:
        raise HTTPException(status_code=403, detail="Not enough permissions")
        
    from app.models.course import Course
    stmt = (
        select(Certificate, Course.title, User.full_name)
        .join(Course, Certificate.course_id == Course.id)
        .join(User, Certificate.user_id == User.id)
        .order_by(Certificate.issued_at.desc())
    )
    result = await db.execute(stmt)
    
    certs = []
    for cert, course_title, full_name in result.all():
        certs.append({
            "id": str(cert.id),
            "certificate_number": cert.certificate_number,
            "course_name": course_title,
            "pdf_url": cert.pdf_url,
            "issued_at": cert.issued_at,
            "student_name": full_name
        })
    return certs
