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

class AIImageRequest(BaseModel):
    prompt: str

class AIImageResponse(BaseModel):
    image_url: str

@router.post("/image", response_model=AIImageResponse)
async def generate_course_image(
    request: AIImageRequest,
    current_user: User = Depends(deps.get_current_active_user)
) -> Any:
    """
    Generate a course backdrop image using Pollinations AI.
    """
    if current_user.role not in ["admin", "creator"]:
        raise HTTPException(status_code=403, detail="Not enough permissions")

    import urllib.parse
    # URL encode the prompt
    encoded_prompt = urllib.parse.quote(request.prompt)
    
    # Generate a random seed so same prompt gives different images
    import random
    seed = random.randint(1, 100000)
    
    # Use Pollinations AI (free, no API key needed)
    # nologo=true removes the watermark, width=1024, height=512 for a good backdrop ratio
    image_url = f"https://image.pollinations.ai/prompt/{encoded_prompt}?width=1024&height=512&nologo=true&seed={seed}"

    return AIImageResponse(image_url=image_url)
