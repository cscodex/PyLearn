from pydantic import BaseModel
class Req(BaseModel):
    answers: dict[int, int]

try:
    r = Req.model_validate({"answers": {"1": 2}})
    print(r.answers, type(list(r.answers.keys())[0]))
except Exception as e:
    print(e)
