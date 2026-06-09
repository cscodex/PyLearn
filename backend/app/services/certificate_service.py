import os
import io
import cloudinary.uploader
from PIL import Image, ImageDraw, ImageFont
import datetime

BASE_DIR = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
ASSETS_DIR = os.path.join(BASE_DIR, "assets")
FONTS_DIR = os.path.join(ASSETS_DIR, "fonts")
TEMPLATE_PATH = os.path.join(ASSETS_DIR, "template.jpg")

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

def generate_certificate_image(student_name: str, course_name: str, date_str: str, certificate_id: str) -> bytes:
    # Open the template
    try:
        img = Image.open(TEMPLATE_PATH).convert('RGB')
    except Exception as e:
        print(f"Error opening template: {e}")
        # Fallback to a blank image if template is missing
        img = Image.new('RGB', (1492, 1054), color='#FDFBF7')
        
    draw = ImageDraw.Draw(img)

    # White out the original text boxes so they are blank
    draw.rectangle([350, 310, 1150, 420], fill="#FCFDFD")  # Name
    draw.rectangle([300, 435, 1200, 505], fill="#FCFDFD")  # Course
    draw.rectangle([130, 715, 1080, 755], fill="#FCFDFD")  # Stats

    # Fonts
    name_font = _get_font("GreatVibes-Regular.ttf", 100)
    course_font = _get_font("Roboto-Bold.ttf", 45)
    stat_font = _get_font("Roboto-Regular.ttf", 20)

    # Text Colors
    primary_color = "#1E3A8A" # Deep blue used in the template
    dark_gray = "#333333"

    # Draw Student Name
    draw_centered(draw, 1492/2, 350, student_name, name_font, fill=primary_color)
    
    # Draw Course Name
    draw_centered(draw, 1492/2, 465, course_name, course_font, fill=primary_color)

    # Draw Stats (Date, ID, Duration, Score, Grade)
    # Positions based on template columns
    draw_centered(draw, 225, 735, date_str, stat_font, dark_gray)
    draw_centered(draw, 415, 735, certificate_id, stat_font, dark_gray)
    draw_centered(draw, 590, 735, "40 Hours", stat_font, dark_gray)
    draw_centered(draw, 715, 735, "100%", stat_font, dark_gray)
    draw_centered(draw, 830, 735, "A+", stat_font, dark_gray)

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

def generate_and_upload_certificate(student_name: str, course_name: str, certificate_id: str) -> str:
    date_str = datetime.datetime.now().strftime("%d %b %Y")
    image_bytes = generate_certificate_image(student_name, course_name, date_str, certificate_id)
    return upload_certificate_to_cloudinary(image_bytes, certificate_id)
