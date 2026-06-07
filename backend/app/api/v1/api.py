from fastapi import APIRouter
from app.api.v1.endpoints import auth, upload, courses, execution, quiz, leaderboard, users, creator_courses, admin, creator_groups

api_router = APIRouter()
api_router.include_router(auth.router, prefix="/auth", tags=["auth"])
api_router.include_router(courses.router, prefix="/courses", tags=["courses"])
api_router.include_router(creator_courses.router, prefix="/creator", tags=["creator"])
api_router.include_router(creator_groups.router, prefix="/creator/groups", tags=["creator-groups"])
api_router.include_router(admin.router, prefix="/admin", tags=["admin"])
api_router.include_router(execution.router, prefix="/execute", tags=["execution"])
api_router.include_router(quiz.router, prefix="/quiz", tags=["quiz"])
api_router.include_router(upload.router, prefix="/upload", tags=["upload"])
api_router.include_router(leaderboard.router, prefix="/leaderboard", tags=["leaderboard"])
api_router.include_router(users.router, prefix="/users", tags=["users"])
