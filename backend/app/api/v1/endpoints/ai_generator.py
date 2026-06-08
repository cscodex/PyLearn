from fastapi import APIRouter, Depends, HTTPException
from typing import Any, List, Dict
from pydantic import BaseModel
from app.api import deps
from app.models.user import User
import asyncio

router = APIRouter()

class AIGenerateRequest(BaseModel):
    prompt: str
    model: str # "Llama" or "Google AI"

class AIModuleResponse(BaseModel):
    title: str
    description: str
    chapters: List[Dict[str, str]]

class AIGenerateResponse(BaseModel):
    modules: List[AIModuleResponse]

@router.post("/generate", response_model=AIGenerateResponse)
async def generate_course_structure(
    request: AIGenerateRequest,
    current_user: User = Depends(deps.get_current_active_user)
) -> Any:
    """
    Generate course structure using AI.
    This is a mocked response for now.
    """
    if current_user.role not in ["admin", "creator"]:
        raise HTTPException(status_code=403, detail="Not enough permissions")

    # Simulate network delay for AI generation
    await asyncio.sleep(2.0)

    # Return mocked structure based on prompt
    modules = [
        AIModuleResponse(
            title=f"Introduction to {request.prompt}",
            description=f"Basic concepts and fundamentals of {request.prompt}.",
            chapters=[
                {"title": "Getting Started"},
                {"title": "Core Principles"}
            ]
        ),
        AIModuleResponse(
            title=f"Intermediate {request.prompt}",
            description=f"Deeper dive into {request.prompt} concepts.",
            chapters=[
                {"title": "Advanced Techniques"},
                {"title": "Practical Examples"}
            ]
        ),
        AIModuleResponse(
            title=f"Mastering {request.prompt}",
            description=f"Expert level applications of {request.prompt}.",
            chapters=[
                {"title": "Best Practices"},
                {"title": "Final Project"}
            ]
        )
    ]

    return AIGenerateResponse(modules=modules)
