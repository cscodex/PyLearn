import cloudinary
import cloudinary.uploader
from fastapi import UploadFile
from app.core.config import settings

# Initialize Cloudinary
if settings.CLOUDINARY_URL:
    cloudinary.config(
        cloudinary_url=settings.CLOUDINARY_URL
    )

async def upload_file(file: UploadFile, folder: str = "pythontutor") -> str:
    """Upload a file to Cloudinary and return the URL."""
    if not settings.CLOUDINARY_URL:
        # Mock upload for local development
        return f"https://mock.cloudinary.com/pythontutor/{file.filename}"
        
    try:
        # Read file contents
        contents = await file.read()
        
        # Upload to Cloudinary
        result = cloudinary.uploader.upload(
            contents,
            folder=folder,
            resource_type="auto"
        )
        return result.get("secure_url")
    except Exception as e:
        print(f"Error uploading to Cloudinary: {str(e)}")
        return ""
