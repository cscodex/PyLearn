from pydantic import BaseModel, Field

class Course(BaseModel):
    difficulty_level: str = Field(validation_alias="difficulty", serialization_alias="difficultyLevel")

c = Course.model_validate({"difficulty": "beginner"})
print(c.model_dump(by_alias=True))
