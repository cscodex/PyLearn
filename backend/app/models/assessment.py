from sqlalchemy import Column, String, Boolean, DateTime, ForeignKey, Integer, Text, Numeric, func, JSON
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.db.base_class import Base

class Question(Base):
    __tablename__ = "questions"
    
    id = Column(Integer, primary_key=True, index=True)
    lesson_id = Column(Integer, ForeignKey("lessons.id", ondelete="CASCADE"), nullable=False)
    question_type = Column(String(30), nullable=False)
    question_text = Column(Text, nullable=False)
    question_data = Column(JSON, nullable=False)
    explanation = Column(Text, nullable=True)
    difficulty = Column(String(20), default="medium")
    points = Column(Integer, default=1)
    order_index = Column(Integer, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    lesson = relationship("Lesson")
    options = relationship("QuestionOption", back_populates="question", cascade="all, delete-orphan")

class QuestionOption(Base):
    __tablename__ = "question_options"
    
    id = Column(Integer, primary_key=True, index=True)
    question_id = Column(Integer, ForeignKey("questions.id", ondelete="CASCADE"), nullable=False)
    option_text = Column(Text, nullable=False)
    is_correct = Column(Boolean, default=False)
    order_index = Column(Integer, nullable=False)
    
    question = relationship("Question", back_populates="options")

class CodingChallenge(Base):
    __tablename__ = "coding_challenges"
    
    id = Column(Integer, primary_key=True, index=True)
    lesson_id = Column(Integer, ForeignKey("lessons.id", ondelete="CASCADE"), nullable=True)
    title = Column(String(255), nullable=False)
    description = Column(Text, nullable=False)
    difficulty = Column(String(20), default="easy")
    starter_code = Column(Text, default="")
    solution_code = Column(Text, nullable=True)
    hints = Column(JSON, nullable=True)
    xp_reward = Column(Integer, default=20)
    time_limit_seconds = Column(Integer, default=5)
    memory_limit_mb = Column(Integer, default=64)
    order_index = Column(Integer, default=0)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    lesson = relationship("Lesson")
    test_cases = relationship("TestCase", back_populates="challenge", cascade="all, delete-orphan")

class TestCase(Base):
    __tablename__ = "test_cases"
    
    id = Column(Integer, primary_key=True, index=True)
    challenge_id = Column(Integer, ForeignKey("coding_challenges.id", ondelete="CASCADE"), nullable=False)
    input_data = Column(Text, nullable=False)
    expected_output = Column(Text, nullable=False)
    is_hidden = Column(Boolean, default=False)
    points = Column(Integer, default=1)
    order_index = Column(Integer, nullable=False)
    
    challenge = relationship("CodingChallenge", back_populates="test_cases")

class QuizSubmission(Base):
    __tablename__ = "quiz_submissions"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    question_id = Column(Integer, ForeignKey("questions.id", ondelete="CASCADE"), nullable=False)
    answer_data = Column(JSON, nullable=False)
    is_correct = Column(Boolean, nullable=True)
    score = Column(Numeric(5, 2), default=0)
    xp_earned = Column(Integer, default=0)
    time_taken_seconds = Column(Integer, nullable=True)
    attempt_number = Column(Integer, default=1)
    submitted_at = Column(DateTime(timezone=True), server_default=func.now())

class CodeSubmission(Base):
    __tablename__ = "code_submissions"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    challenge_id = Column(Integer, ForeignKey("coding_challenges.id", ondelete="CASCADE"), nullable=False)
    source_code = Column(Text, nullable=False)
    status = Column(String(20), default="evaluated")
    score = Column(Numeric(5, 2), default=0)
    test_cases_passed = Column(Integer, default=0)
    test_cases_total = Column(Integer, default=0)
    execution_time_ms = Column(Integer, nullable=True)
    test_results = Column(JSON, nullable=True)
    xp_earned = Column(Integer, default=0)
    submitted_at = Column(DateTime(timezone=True), server_default=func.now())
