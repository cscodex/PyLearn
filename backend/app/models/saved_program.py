from sqlalchemy import Column, Integer, String, Text, DateTime, ForeignKey, JSON
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.db.base_class import Base

from sqlalchemy.dialects.postgresql import UUID
import uuid

class SavedProgram(Base):
    __tablename__ = "saved_programs"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    title = Column(String(100), nullable=False)
    code = Column(Text, nullable=False)
    language = Column(String(50), default="python")
    lesson_id = Column(Integer, ForeignKey("lessons.id", ondelete="SET NULL"), nullable=True)
    terminal_output = Column(Text, nullable=True)
    plots = Column(JSON, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    user = relationship("User", back_populates="saved_programs")
