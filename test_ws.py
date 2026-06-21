import asyncio
import websockets
import json

async def test():
    uri = "wss://pythontutor-api.onrender.com/api/v1/execute/ws"
    async with websockets.connect(uri) as ws:
        code = """
n = int(input("Enter terms: "))
for i in range(n): print(i)
"""
        await ws.send(json.dumps({"code": code}))
        
        while True:
            msg = await ws.recv()
            print("Received:", msg)
            data = json.loads(msg)
            if data.get("type") == "input_request":
                print("Sending input '3'...")
                await ws.send(json.dumps({"action": "input", "data": "3"}))
            elif data.get("type") == "completed":
                break

asyncio.run(test())
