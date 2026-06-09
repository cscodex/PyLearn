import os
from PIL import Image, ImageDraw, ImageFont

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
TEMPLATE_PATH = os.path.join(BASE_DIR, "assets", "template.jpg")
FONTS_DIR = os.path.join(BASE_DIR, "assets", "fonts")
OUTPUT_PATH = "/Users/charanpreetsingh/.gemini/antigravity/brain/fe9d58ed-a6d1-4186-9cb6-ca24d7c7bf74/sample_certificate.jpg"

img = Image.open(TEMPLATE_PATH).convert('RGB')
draw = ImageDraw.Draw(img)

# White out the original name
draw.rectangle([350, 310, 1150, 420], fill="#FBFBFB")
# White out the course name
draw.rectangle([400, 440, 1100, 500], fill="#FBFBFB")
# White out the stats row
draw.rectangle([130, 720, 1080, 755], fill="#FBFBFB")

def _get_font(font_name, size):
    return ImageFont.truetype(os.path.join(FONTS_DIR, font_name), size)

name_font = _get_font("GreatVibes-Regular.ttf", 90)
course_font = _get_font("Roboto-Bold.ttf", 45)
stat_font = _get_font("Roboto-Regular.ttf", 20)

def draw_centered(x_center, y_center, text, font, fill="#1e3a8a"):
    bbox = draw.textbbox((0, 0), text, font=font)
    w = bbox[2] - bbox[0]
    h = bbox[3] - bbox[1]
    draw.text((x_center - w/2, y_center - h/2), text, font=font, fill=fill)

draw_centered(1492/2, 345, "Charanpreet Singh", name_font)
draw_centered(1492/2, 460, "Advanced Python Engineering", course_font)

# Stats:
draw_centered(225, 730, "09 Jun 2026", stat_font, "#333")
draw_centered(415, 730, "PY-2026-X891", stat_font, "#333")
draw_centered(590, 730, "40 Hours", stat_font, "#333")
draw_centered(715, 730, "100%", stat_font, "#333")
draw_centered(830, 730, "A+", stat_font, "#333")

img.save(OUTPUT_PATH, quality=95)
print("Saved")
