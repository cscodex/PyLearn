from fastapi import FastAPI
from pydantic import BaseModel
import uvicorn
import requests
import time
import threading

app = FastAPI()

class Req(BaseModel):
    answers: dict[int, int]

@app.post("/")
def test(req: Req):
    return {"type_of_key": str(type(list(req.answers.keys())[0])), "keys": list(req.answers.keys())}

def run_server():
    uvicorn.run(app, host="127.0.0.1", port=8000)

t = threading.Thread(target=run_server, daemon=True)
t.start()
time.sleep(2)
res = requests.post("http://127.0.0.1:8000/", json={"answers": {"1": 2}})
print(res.json())
