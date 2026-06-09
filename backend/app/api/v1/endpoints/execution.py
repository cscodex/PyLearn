from fastapi import APIRouter, Depends, HTTPException
from typing import Any
from sqlalchemy.ext.asyncio import AsyncSession

from app.api import deps
from app.models.user import User
from app.schemas.execution import CodeExecutionRequest, CodeExecutionResponse
from app.services.code_execution import execute_python_code

router = APIRouter()

@router.post("/", response_model=CodeExecutionResponse)
async def execute_code(
    request: CodeExecutionRequest,
    db: AsyncSession = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_active_user)
) -> Any:
    """Execute python code securely."""
    
    result = await execute_python_code(request.code, standard_input=request.standard_input)
    
    # Add XP if successful
    xp_earned = 5 if result["is_success"] else 0
    if xp_earned > 0:
        current_user.xp += xp_earned
        # Update streak logic here eventually
        db.add(current_user)
        await db.commit()
        await db.refresh(current_user)
        
    return CodeExecutionResponse(
        stdout=result["stdout"],
        stderr=result["stderr"],
        execution_time_ms=result["execution_time_ms"],
        is_success=result["is_success"],
        xp_earned=xp_earned
    )
