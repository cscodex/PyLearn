import sys
import os

sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app.services.certificate_service import generate_certificate_image
import uuid

sample_id = str(uuid.uuid4())[:8]
bytes_data = generate_certificate_image(
    student_name="Charanpreet Singh", 
    course_name="Advanced Python Engineering", 
    date_str="09 Jun 2026", 
    certificate_id=sample_id,
    instructor_name="Alice Creator",
    director_name="Bob Admin",
    duration_str="25 Hours",
    score_str="Completed",
    grade_str="-",
    concepts=["Variables", "Loops", "Functions", "Classes", "File I/O"]
)

output_path = "/Users/charanpreetsingh/.gemini/antigravity/brain/fe9d58ed-a6d1-4186-9cb6-ca24d7c7bf74/sample_certificate.jpg"
with open(output_path, "wb") as f:
    f.write(bytes_data)

print(f"Sample certificate saved to {output_path}")
