from pydantic import BaseModel, Field
from typing import Optional, List, Any
from datetime import datetime

class SavedFlowchartBase(BaseModel):
    title: str = Field(..., max_length=100)
    nodes: List[Any] = Field(default_factory=list)
    edges: List[Any] = Field(default_factory=list)

class SavedFlowchartCreate(SavedFlowchartBase):
    pass

class SavedFlowchartUpdate(BaseModel):
    title: Optional[str] = Field(None, max_length=100)
    nodes: Optional[List[Any]] = None
    edges: Optional[List[Any]] = None

class SavedFlowchartInDBBase(SavedFlowchartBase):
    id: int
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True

class SavedFlowchart(SavedFlowchartInDBBase):
    pass
