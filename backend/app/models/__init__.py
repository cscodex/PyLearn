from app.models.user import User, UserProfile, OAuthAccount, RefreshToken
from app.models.course import Course, Module, Chapter, Lesson, LessonResource
from app.models.assessment import Question, QuestionOption, CodingChallenge, TestCase, QuizSubmission, CodeSubmission
from app.models.gamification import UserScore, XpTransaction, Streak, Achievement, UserAchievement
from app.models.progress import Enrollment, UserLessonProgress, Bookmark
from app.models.misc import Certificate, Notification, ActivityLog, PasswordResetToken
from app.models.group import Group, GroupMember, GroupAssignment
from app.models.saved_program import SavedProgram
from app.models.saved_flowchart import SavedFlowchart

# Export all models so Alembic can discover them
__all__ = [
    "User", "UserProfile", "OAuthAccount", "RefreshToken",
    "Course", "Module", "Chapter", "Lesson", "LessonResource",
    "Question", "QuestionOption", "CodingChallenge", "TestCase", "QuizSubmission", "CodeSubmission",
    "UserScore", "XpTransaction", "Streak", "Achievement", "UserAchievement",
    "Enrollment", "UserLessonProgress", "Bookmark",
    "Certificate", "Notification", "ActivityLog", "PasswordResetToken",
    "Group", "GroupMember", "GroupAssignment", "SavedProgram", "SavedFlowchart"
]
