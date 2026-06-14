from fastapi import APIRouter, Depends, HTTPException, status
from typing import Any, List
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import delete

from app.api import deps
from app.models.user import User
from app.models.saved_flowchart import SavedFlowchart
from app.schemas.saved_flowchart import SavedFlowchart as SavedFlowchartSchema, SavedFlowchartCreate, SavedFlowchartUpdate

router = APIRouter()

MAX_FLOWCHARTS_PER_USER = 100

@router.get("/", response_model=List[SavedFlowchartSchema])
async def read_saved_flowcharts(
    db: AsyncSession = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_active_user)
) -> Any:
    """Retrieve saved flowcharts for current user."""
    stmt = select(SavedFlowchart).where(SavedFlowchart.user_id == current_user.id).order_by(SavedFlowchart.created_at.desc())
    result = await db.execute(stmt)
    flowcharts = result.scalars().all()
    return flowcharts

@router.post("/", response_model=SavedFlowchartSchema)
async def create_saved_flowchart(
    *,
    db: AsyncSession = Depends(deps.get_db),
    flowchart_in: SavedFlowchartCreate,
    current_user: User = Depends(deps.get_current_active_user)
) -> Any:
    """Create new saved flowchart."""
    # Check limit
    count_stmt = select(SavedFlowchart).where(SavedFlowchart.user_id == current_user.id)
    result = await db.execute(count_stmt)
    if len(result.scalars().all()) >= MAX_FLOWCHARTS_PER_USER:
        raise HTTPException(
            status_code=400,
            detail=f"You can only save up to {MAX_FLOWCHARTS_PER_USER} flowcharts."
        )
        
    flowchart = SavedFlowchart(
        user_id=current_user.id,
        title=flowchart_in.title,
        nodes=flowchart_in.nodes,
        edges=flowchart_in.edges,
    )
    db.add(flowchart)
    await db.commit()
    await db.refresh(flowchart)
    return flowchart

@router.put("/{flowchart_id}", response_model=SavedFlowchartSchema)
async def update_saved_flowchart(
    *,
    db: AsyncSession = Depends(deps.get_db),
    flowchart_id: int,
    flowchart_in: SavedFlowchartUpdate,
    current_user: User = Depends(deps.get_current_active_user)
) -> Any:
    """Update a saved flowchart."""
    stmt = select(SavedFlowchart).where(SavedFlowchart.id == flowchart_id, SavedFlowchart.user_id == current_user.id)
    result = await db.execute(stmt)
    flowchart = result.scalar_one_or_none()
    
    if not flowchart:
        raise HTTPException(status_code=404, detail="Flowchart not found")
        
    update_data = flowchart_in.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(flowchart, field, value)
        
    db.add(flowchart)
    await db.commit()
    await db.refresh(flowchart)
    return flowchart

@router.delete("/{flowchart_id}")
async def delete_saved_flowchart(
    *,
    db: AsyncSession = Depends(deps.get_db),
    flowchart_id: int,
    current_user: User = Depends(deps.get_current_active_user)
) -> Any:
    """Delete a saved flowchart."""
    stmt = select(SavedFlowchart).where(SavedFlowchart.id == flowchart_id, SavedFlowchart.user_id == current_user.id)
    result = await db.execute(stmt)
    flowchart = result.scalar_one_or_none()
    
    if not flowchart:
        raise HTTPException(status_code=404, detail="Flowchart not found")
        
    await db.delete(flowchart)
    await db.commit()
    return {"success": True}
