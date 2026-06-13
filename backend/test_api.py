import requests

# Login to get token
r = requests.post("http://localhost:8000/api/v1/auth/login", data={"username": "charanpreetsinghg@gmail.com", "password": "password"})
token = r.json().get("access_token")
headers = {"Authorization": f"Bearer {token}"}

# Test /saved-programs/students
r1 = requests.get("http://localhost:8000/api/v1/saved-programs/students", headers=headers)
print("Saved programs /students:", r1.status_code, r1.text[:200])

# Test /creator/enrollments
r2 = requests.get("http://localhost:8000/api/v1/creator/enrollments", headers=headers)
print("Creator enrollments:", r2.status_code, r2.text[:200])

# Test /admin/enrollments
r3 = requests.get("http://localhost:8000/api/v1/admin/enrollments", headers=headers)
print("Admin enrollments:", r3.status_code, r3.text[:200])
