from sqlalchemy import Column, String, Boolean, DateTime, ForeignKey, Integer, Date, Numeric, Text, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.db.base_class import Base

class UserScore(Base):
    __tablename__ = "user_scores"
    
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), primary_key=True)
    total_xp = Column(Integer, default=0)
    weekly_xp = Column(Integer, default=0)
    monthly_xp = Column(Integer, default=0)
    level = Column(Integer, default=1)
    courses_completed = Column(Integer, default=0)
    lessons_completed = Column(Integer, default=0)
    challenges_solved = Column(Integer, default=0)
    quiz_accuracy = Column(Numeric(5, 2), default=0)
    school_name = Column(String(255), nullable=True)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

class XpTransaction(Base):
    __tablename__ = "xp_transactions"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    xp_amount = Column(Integer, nullable=False)
    source_type = Column(String(30), nullable=False)
    source_id = Column(Integer, nullable=True)
    description = Column(String(255), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

class Streak(Base):
    __tablename__ = "streaks"
    
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), primary_key=True)
    current_streak = Column(Integer, default=0)
    longest_streak = Column(Integer, default=0)
    last_activity_date = Column(Date, nullable=True)
    weekly_goal_target = Column(Integer, default=5)
    weekly_goal_progress = Column(Integer, default=0)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

class Achievement(Base):
    __tablename__ = "achievements"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False)
    description = Column(Text, nullable=True)
    icon_name = Column(String(50), nullable=True)
    category = Column(String(30), nullable=True)
    xp_reward = Column(Integer, default=0)
    condition_type = Column(String(50), nullable=False)
    condition_threshold = Column(Integer, nullable=False)
    is_active = Column(Boolean, default=True)

class UserAchievement(Base):
    __tablename__ = "user_achievements"
    
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), primary_key=True)
    achievement_id = Column(Integer, ForeignKey("achievements.id", ondelete="CASCADE"), primary_key=True)
    earned_at = Column(DateTime(timezone=True), server_default=func.now())
