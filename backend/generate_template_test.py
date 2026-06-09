import os
from PIL import Image, ImageDraw

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
TEMPLATE_PATH = os.path.join(BASE_DIR, "assets", "template.jpg")
OUTPUT_PATH = "/Users/charanpreetsingh/.gemini/antigravity/brain/fe9d58ed-a6d1-4186-9cb6-ca24d7c7bf74/bbox_test.jpg"

img = Image.open(TEMPLATE_PATH).convert('RGB')
draw = ImageDraw.Draw(img)

# Python Logo
draw.rectangle([80, 80, 240, 260], fill="red")
# Concepts Row
draw.rectangle([120, 530, 1370, 650], fill="blue")
# Signatures
draw.rectangle([150, 810, 360, 920], fill="green") # Left sig
draw.rectangle([650, 810, 850, 920], fill="purple") # Left sig (Wait, right is further right)
draw.rectangle([1020, 810, 1340, 920], fill="orange") # Right sig

img.save(OUTPUT_PATH, quality=70)
print("Saved bbox test")
