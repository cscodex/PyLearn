from sqlalchemy import Column, String, Boolean, DateTime, ForeignKey, Integer, Text, Numeric, func, JSON
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.db.base_class import Base

class Course(Base):
    __tablename__ = "courses"
    
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(255), nullable=False)
    slug = Column(String(255), unique=True, index=True, nullable=False)
    description = Column(Text, nullable=True)
    thumbnail_url = Column(Text, nullable=True)
    difficulty = Column(String(20), default="beginner", nullable=False)
    instructor_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=True)
    estimated_hours = Column(Numeric(5, 1), nullable=True)
    total_lessons = Column(Integer, default=0)
    total_enrollments = Column(Integer, default=0)
    is_published = Column(Boolean, default=False, index=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    
    modules = relationship("Module", back_populates="course", cascade="all, delete-orphan")
    enrollments = relationship("Enrollment", back_populates="course")

class Module(Base):
    __tablename__ = "modules"
    
    id = Column(Integer, primary_key=True, index=True)
    course_id = Column(Integer, ForeignKey("courses.id", ondelete="CASCADE"), nullable=False)
    title = Column(String(255), nullable=False)
    description = Column(Text, nullable=True)
    order_index = Column(Integer, nullable=False)
    
    course = relationship("Course", back_populates="modules")
    chapters = relationship("Chapter", back_populates="module", cascade="all, delete-orphan")

class Chapter(Base):
    __tablename__ = "chapters"
    
    id = Column(Integer, primary_key=True, index=True)
    module_id = Column(Integer, ForeignKey("modules.id", ondelete="CASCADE"), nullable=False)
    title = Column(String(255), nullable=False)
    description = Column(Text, nullable=True)
    order_index = Column(Integer, nullable=False)
    
    module = relationship("Module", back_populates="chapters")
    lessons = relationship("Lesson", back_populates="chapter", cascade="all, delete-orphan")

class Lesson(Base):
    __tablename__ = "lessons"
    
    id = Column(Integer, primary_key=True, index=True)
    chapter_id = Column(Integer, ForeignKey("chapters.id", ondelete="CASCADE"), nullable=False)
    title = Column(String(255), nullable=False)
    content_type = Column(String(30), nullable=False)
    content_body = Column(JSON, nullable=True)
    video_url = Column(Text, nullable=True)
    duration_minutes = Column(Integer, nullable=True)
    order_index = Column(Integer, nullable=False)
    xp_reward = Column(Integer, default=10)
    is_free_preview = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    
    chapter = relationship("Chapter", back_populates="lessons")
    resources = relationship("LessonResource", back_populates="lesson", cascade="all, delete-orphan")

class LessonResource(Base):
    __tablename__ = "lesson_resources"
    
    id = Column(Integer, primary_key=True, index=True)
    lesson_id = Column(Integer, ForeignKey("lessons.id", ondelete="CASCADE"), nullable=False)
    title = Column(String(255), nullable=False)
    resource_type = Column(String(30), nullable=True)
    url = Column(Text, nullable=False)
    cloudinary_public_id = Column(String(255), nullable=True)
    file_size_bytes = Column(Integer, nullable=True)
    order_index = Column(Integer, default=0)
    
    lesson = relationship("Lesson", back_populates="resources")
