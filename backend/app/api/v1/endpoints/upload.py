from fastapi import APIRouter, Depends, UploadFile, File, HTTPException
from typing import Any
from app.api import deps
from app.services.cloudinary_service import upload_file
from app.models.user import User

router = APIRouter()

@router.post("/image", response_model=dict)
async def upload_image(
    file: UploadFile = File(...),
    current_user: User = Depends(deps.get_current_active_user)
) -> Any:
    """Upload an image to Cloudinary (e.g. for user avatar)."""
    # iOS image picker sometimes sends application/octet-stream, so we relax this check
    if not file.content_type.startswith("image/") and file.content_type != "application/octet-stream":
        # we'll let Cloudinary do the actual file validation
        pass
        
    url = await upload_file(file, folder=f"pythontutor/users/{current_user.id}")
    if not url:
        raise HTTPException(status_code=500, detail="Error uploading file")
        
    return {"url": url}
