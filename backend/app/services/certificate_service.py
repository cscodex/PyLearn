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
ABSTRACT_BG_PATH = os.path.join(ASSETS_DIR, "abstract_bg.png")
GOLD_STAR_PATH = os.path.join(ASSETS_DIR, "gold_star.png")

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
    width, height = 1500, 1060
    img = Image.new("RGB", (width, height), color="#FDFBF7") # Cream background
    
    try:
        bg = Image.open(ABSTRACT_BG_PATH).convert("RGBA")
        bg = bg.resize((width, height), Image.Resampling.LANCZOS)
        bg.putalpha(60) # Fade background to ~24% opacity
        img.paste(bg, (0, 0), bg)
    except Exception as e:
        print(f"Error loading background: {e}")
        pass
        
    draw = ImageDraw.Draw(img)

    primary_color = "#1E3A8A" # Navy
    gold_color = "#D4AF37" # Gold
    dark_gray = "#333333"

    # --- Draw Borders ---
    # Outer Gold Border
    draw.rectangle([40, 40, width-40, height-40], outline=gold_color, width=12)
    # Inner Navy Border
    draw.rectangle([60, 60, width-60, height-60], outline=primary_color, width=4)
    # Decorative thin inner border
    draw.rectangle([70, 70, width-70, height-70], outline=gold_color, width=1)

    # --- Fonts ---
    title_font = _get_font("Roboto-Bold.ttf", 70)
    subtitle_font = _get_font("Roboto-Bold.ttf", 25)
    name_font = _get_font("GreatVibes-Regular.ttf", 100)
    
    # Dynamic course font size
    max_course_width = 1300
    course_font_size = 70
    course_font = _get_font("Roboto-Bold.ttf", course_font_size)
    while course_font_size > 20:
        bbox = draw.textbbox((0, 0), course_name, font=course_font)
        if (bbox[2] - bbox[0]) <= max_course_width:
            break
        course_font_size -= 2
        course_font = _get_font("Roboto-Bold.ttf", course_font_size)
        
    stat_font = _get_font("Roboto-Regular.ttf", 20)
    stat_bold_font = _get_font("Roboto-Bold.ttf", 20)
    signature_font = _get_font("GreatVibes-Regular.ttf", 60)
    sig_title_font = _get_font("Roboto-Bold.ttf", 18)
    concept_font = _get_font("Roboto-Regular.ttf", 20)

    # --- Header ---
    # Logo
    try:
        app_logo = Image.open(APP_ICON_PATH).convert("RGBA")
        app_logo = app_logo.resize((120, 120), Image.Resampling.LANCZOS)
        img.paste(app_logo, (width//2 - 60, 100), app_logo)
    except Exception:
        pass
    
    draw_centered(draw, width/2, 260, "CERTIFICATE OF COMPLETION", title_font, fill=primary_color)
    draw_centered(draw, width/2, 330, "THIS IS PROUDLY PRESENTED TO", subtitle_font, fill=gold_color)

    # --- Student Name ---
    draw_centered(draw, width/2, 450, student_name, name_font, fill=primary_color)
    draw.line([(width/2 - 400, 520), (width/2 + 400, 520)], fill=gold_color, width=2)

    # --- Description ---
    draw_centered(draw, width/2, 570, "For successfully completing the rigorous requirements of the", stat_font, fill=dark_gray)
    draw_centered(draw, width/2, 630, course_name, course_font, fill=primary_color)

    # --- Concepts ---
    if concepts:
        display_concepts = concepts[:5]
        spacing = width / (len(display_concepts) + 1)
        
        try:
            star_icon = Image.open(GOLD_STAR_PATH).convert("RGBA")
            star_icon = star_icon.resize((20, 20), Image.Resampling.LANCZOS)
        except Exception:
            star_icon = None
            
        for i, concept in enumerate(display_concepts):
            x_pos = spacing * (i + 1)
            # Center the concept text
            bbox = draw.textbbox((0, 0), concept, font=concept_font)
            text_w = bbox[2] - bbox[0]
            
            if star_icon:
                # Paste star to the left of the text
                img.paste(star_icon, (int(x_pos - text_w/2 - 25), 712), star_icon)
                draw.text((x_pos - text_w/2, 710), concept, font=concept_font, fill=dark_gray)
            else:
                bullet = "★ " + concept
                draw_centered(draw, x_pos, 720, bullet, concept_font, dark_gray)

    # --- Stats Row ---
    # Grouped at the bottom center
    stat_y = 820
    draw_centered(draw, 350, stat_y - 25, "DATE", stat_bold_font, primary_color)
    draw_centered(draw, 350, stat_y, date_str, stat_font, dark_gray)

    draw_centered(draw, 550, stat_y - 25, "ID", stat_bold_font, primary_color)
    draw_centered(draw, 550, stat_y, certificate_id, stat_font, dark_gray)

    draw_centered(draw, 750, stat_y - 25, "DURATION", stat_bold_font, primary_color)
    draw_centered(draw, 750, stat_y, duration_str, stat_font, dark_gray)

    draw_centered(draw, 950, stat_y - 25, "SCORE", stat_bold_font, primary_color)
    draw_centered(draw, 950, stat_y, score_str, stat_font, dark_gray)

    draw_centered(draw, 1150, stat_y - 25, "GRADE", stat_bold_font, primary_color)
    draw_centered(draw, 1150, stat_y, grade_str, stat_font, dark_gray)

    # --- Signatures ---
    sig_y = 880
    # Left (Instructor)
    draw_centered(draw, 300, sig_y, instructor_name, signature_font, dark_gray)
    draw.line([(200, sig_y + 30), (400, sig_y + 30)], fill=dark_gray, width=1)
    draw_centered(draw, 300, sig_y + 50, "Instructor", sig_title_font, primary_color)

    # Right (Director)
    draw_centered(draw, 1200, sig_y, director_name, signature_font, dark_gray)
    draw.line([(1100, sig_y + 30), (1300, sig_y + 30)], fill=dark_gray, width=1)
    draw_centered(draw, 1200, sig_y + 50, "Director", sig_title_font, primary_color)

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
