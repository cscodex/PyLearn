from pydantic import BaseModel
class Test(BaseModel):
    answers: dict[int, int]

t = Test.parse_raw('{"answers": {"1": 2}}')
print(t.answers)
print(type(list(t.answers.keys())[0]))
