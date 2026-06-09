from fastapi import APIRouter, Depends, HTTPException, status
from typing import Any, List
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import func

from app.api import deps
from app.models.user import User
from app.models.saved_program import SavedProgram
from app.schemas.saved_program import SavedProgram as SavedProgramSchema, SavedProgramCreate, SavedProgramUpdate

router = APIRouter()

MAX_PROGRAMS_PER_USER = 100

@router.get("/", response_model=List[SavedProgramSchema])
async def read_saved_programs(
    db: AsyncSession = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_active_user)
) -> Any:
    """Retrieve saved programs for current user."""
    stmt = select(SavedProgram).where(SavedProgram.user_id == current_user.id).order_by(SavedProgram.created_at.desc())
    result = await db.execute(stmt)
    programs = result.scalars().all()
    return programs

@router.post("/", response_model=SavedProgramSchema)
async def create_saved_program(
    *,
    db: AsyncSession = Depends(deps.get_db),
    program_in: SavedProgramCreate,
    current_user: User = Depends(deps.get_current_active_user)
) -> Any:
    """Create new saved program."""
    
    # Check limit
    count_stmt = select(func.count()).select_from(SavedProgram).where(SavedProgram.user_id == current_user.id)
    count_result = await db.execute(count_stmt)
    count = count_result.scalar_one()
    
    if count >= MAX_PROGRAMS_PER_USER:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"You have reached the maximum limit of {MAX_PROGRAMS_PER_USER} saved programs. Please delete some before saving new ones."
        )

    # Check for existing with same name to overwrite? No, just create new. 
    # Or maybe we can enforce unique titles? Let's just create.
    
    db_obj = SavedProgram(
        **program_in.model_dump(),
        user_id=current_user.id
    )
    db.add(db_obj)
    await db.commit()
    await db.refresh(db_obj)
    return db_obj

@router.put("/{program_id}", response_model=SavedProgramSchema)
async def update_saved_program(
    *,
    db: AsyncSession = Depends(deps.get_db),
    program_id: int,
    program_in: SavedProgramUpdate,
    current_user: User = Depends(deps.get_current_active_user)
) -> Any:
    """Update a saved program."""
    stmt = select(SavedProgram).where(SavedProgram.id == program_id, SavedProgram.user_id == current_user.id)
    result = await db.execute(stmt)
    program = result.scalar_one_or_none()
    
    if not program:
        raise HTTPException(status_code=404, detail="Program not found")
        
    update_data = program_in.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(program, field, value)
        
    db.add(program)
    await db.commit()
    await db.refresh(program)
    return program

@router.delete("/{program_id}", response_model=SavedProgramSchema)
async def delete_saved_program(
    *,
    db: AsyncSession = Depends(deps.get_db),
    program_id: int,
    current_user: User = Depends(deps.get_current_active_user)
) -> Any:
    """Delete a saved program."""
    stmt = select(SavedProgram).where(SavedProgram.id == program_id, SavedProgram.user_id == current_user.id)
    result = await db.execute(stmt)
    program = result.scalar_one_or_none()
    
    if not program:
        raise HTTPException(status_code=404, detail="Program not found")
        
    await db.delete(program)
    await db.commit()
    return program
