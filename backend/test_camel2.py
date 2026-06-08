from pydantic import BaseModel, ConfigDict, Field, AliasChoices
from pydantic.alias_generators import to_camel

class TestModel(BaseModel):
    model_config = ConfigDict(alias_generator=to_camel, populate_by_name=True, from_attributes=True)
    difficulty_level: str = Field(validation_alias=AliasChoices('difficulty', 'difficulty_level'))
    thumbnail_url: str

class DBModel:
    def __init__(self):
        self.difficulty = "beginner"
        self.thumbnail_url = "http://example.com/image.png"

db_model = DBModel()
pydantic_model = TestModel.model_validate(db_model)
print(pydantic_model.model_dump(by_alias=True))
