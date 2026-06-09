import os
import io
import cloudinary.uploader
from PIL import Image, ImageDraw, ImageFont
import datetime
from typing import List

BASE_DIR = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
ASSETS_DIR = os.path.join(BASE_DIR, "assets")
FONTS_DIR = os.path.join(ASSETS_DIR, "fonts")
TEMPLATE_PATH = os.path.join(ASSETS_DIR, "template.jpg")
APP_ICON_PATH = os.path.join(ASSETS_DIR, "app_icon.png")

def _get_font(font_name: str, size: int) -> ImageFont.FreeTypeFont:
    font_path = os.path.join(FONTS_DIR, font_name)
    try:
        return ImageFont.truetype(font_path, size)
    except Exception:
        return ImageFont.load_default()

def draw_centered(draw, x_center, y_center, text, font, fill="#1e3a8a"):
    bbox = draw.textbbox((0, 0), text, font=font)
    w = bbox[2] - bbox[0]
    h = bbox[3] - bbox[1]
    draw.text((x_center - w/2, y_center - h/2), text, font=font, fill=fill)

def generate_certificate_image(
    student_name: str, 
    course_name: str, 
    date_str: str, 
    certificate_id: str,
    instructor_name: str,
    director_name: str,
    duration_str: str,
    score_str: str,
    grade_str: str,
    concepts: List[str]
) -> bytes:
    # Open the template
    try:
        img = Image.open(TEMPLATE_PATH).convert('RGB')
    except Exception as e:
        print(f"Error opening template: {e}")
        img = Image.new('RGB', (1492, 1054), color='#FDFBF7')
        
    draw = ImageDraw.Draw(img)

    bg_color = "#FDFCFB" # Match the off-white center background

    # 1. Blank out Original Logo
    draw.rectangle([60, 60, 270, 270], fill=bg_color)
    
    # Paste App Logo
    try:
        app_logo = Image.open(APP_ICON_PATH).convert("RGBA")
        app_logo = app_logo.resize((150, 150), Image.Resampling.LANCZOS)
        # Paste using alpha channel as mask
        img.paste(app_logo, (100, 90), app_logo)
    except Exception as e:
        print(f"Could not load app logo: {e}")

    # 2. Blank out Name, Course, Stats
    draw.rectangle([350, 310, 1150, 420], fill=bg_color)  # Name
    draw.rectangle([300, 435, 1200, 505], fill=bg_color)  # Course
    draw.rectangle([130, 715, 1080, 755], fill=bg_color)  # Stats

    # 3. Blank out Concepts Row
    draw.rectangle([100, 520, 1390, 660], fill=bg_color)

    # 4. Blank out Signatures
    draw.rectangle([130, 800, 390, 930], fill=bg_color)   # Left signature (Instructor)
    draw.rectangle([1000, 800, 1360, 930], fill=bg_color) # Right signature (Director)

    # Fonts
    name_font = _get_font("GreatVibes-Regular.ttf", 100)
    course_font = _get_font("Roboto-Bold.ttf", 45)
    stat_font = _get_font("Roboto-Regular.ttf", 20)
    signature_font = _get_font("GreatVibes-Regular.ttf", 60)
    title_font = _get_font("Roboto-Bold.ttf", 18)
    concept_font = _get_font("Roboto-Regular.ttf", 18)

    # Text Colors
    primary_color = "#1E3A8A" # Deep blue
    dark_gray = "#333333"

    # Draw Student Name
    draw_centered(draw, 1492/2, 350, student_name, name_font, fill=primary_color)
    
    # Draw Course Name
    draw_centered(draw, 1492/2, 465, course_name, course_font, fill=primary_color)

    # Draw Stats (Date, ID, Duration, Score, Grade)
    draw_centered(draw, 225, 735, date_str, stat_font, dark_gray)
    draw_centered(draw, 415, 735, certificate_id, stat_font, dark_gray)
    draw_centered(draw, 590, 735, duration_str, stat_font, dark_gray)
    draw_centered(draw, 715, 735, score_str, stat_font, dark_gray)
    draw_centered(draw, 830, 735, grade_str, stat_font, dark_gray)

    # Draw Signatures
    # Left (Instructor)
    draw_centered(draw, 260, 850, instructor_name, signature_font, dark_gray)
    draw.line([(160, 890), (360, 890)], fill=dark_gray, width=1)
    draw_centered(draw, 260, 910, "Instructor", title_font, primary_color)

    # Right (Director)
    draw_centered(draw, 1180, 850, director_name, signature_font, dark_gray)
    draw.line([(1080, 890), (1280, 890)], fill=dark_gray, width=1)
    draw_centered(draw, 1180, 910, "Director", title_font, primary_color)

    # Draw Concepts
    # Distribute the concepts evenly across the row (y=590)
    if concepts:
        # Max 6 concepts to fit properly
        display_concepts = concepts[:6]
        total_width = 1492
        spacing = total_width / (len(display_concepts) + 1)
        for i, concept in enumerate(display_concepts):
            x_pos = spacing * (i + 1)
            # Add a small bullet point before the concept
            bullet = "• " + concept
            draw_centered(draw, x_pos, 590, bullet, concept_font, dark_gray)

    # Save to BytesIO
    img_byte_arr = io.BytesIO()
    img.save(img_byte_arr, format='JPEG', quality=95)
    return img_byte_arr.getvalue()

def upload_certificate_to_cloudinary(image_bytes: bytes, certificate_id: str) -> str:
    try:
        response = cloudinary.uploader.upload(
            image_bytes,
            resource_type="image",
            folder="pylearn_certificates",
            public_id=f"cert_{certificate_id}"
        )
        return response.get('secure_url')
    except Exception as e:
        print(f"Cloudinary upload error: {e}")
        return ""

def generate_and_upload_certificate(
    student_name: str, 
    course_name: str, 
    certificate_id: str,
    instructor_name: str,
    director_name: str,
    duration_str: str,
    score_str: str,
    grade_str: str,
    concepts: List[str]
) -> str:
    date_str = datetime.datetime.now().strftime("%d %b %Y")
    image_bytes = generate_certificate_image(
        student_name, course_name, date_str, certificate_id,
        instructor_name, director_name, duration_str, score_str, grade_str, concepts
    )
    return upload_certificate_to_cloudinary(image_bytes, certificate_id)
