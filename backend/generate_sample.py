import sys
import os

# Add backend to path so imports work
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app.services.certificate_service import generate_certificate_image
import uuid

sample_id = str(uuid.uuid4())[:8]
bytes_data = generate_certificate_image("Charanpreet Singh", "Advanced Python Programming", "June 9, 2026", sample_id)

output_path = "/Users/charanpreetsingh/.gemini/antigravity/brain/fe9d58ed-a6d1-4186-9cb6-ca24d7c7bf74/sample_certificate.jpg"
with open(output_path, "wb") as f:
    f.write(bytes_data)

print(f"Sample certificate saved to {output_path}")
