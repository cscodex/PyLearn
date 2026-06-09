import os
import io
import cloudinary.uploader
from PIL import Image, ImageDraw, ImageFont
import datetime

# Determine base dir
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASSETS_DIR = os.path.join(BASE_DIR, "assets")
FONTS_DIR = os.path.join(ASSETS_DIR, "fonts")

def _get_font(font_name: str, size: int) -> ImageFont.FreeTypeFont:
    font_path = os.path.join(FONTS_DIR, font_name)
    try:
        return ImageFont.truetype(font_path, size)
    except Exception:
        # Fallback to default if font missing
        return ImageFont.load_default()

def generate_certificate_image(student_name: str, course_name: str, date_str: str, certificate_id: str) -> bytes:
    """Generate a certificate image using Pillow and return as JPEG bytes."""
    # Create a blank high-res canvas (A4 Landscape at 150 DPI approx)
    width, height = 1754, 1240
    img = Image.new('RGB', (width, height), color='#FFFFFF')
    draw = ImageDraw.Draw(img)

    # Colors
    primary_color = "#1E1B4B" # Deep purple/navy
    accent_color = "#4338CA"  # Indigo
    gold_color = "#D97706"    # Amber/Gold
    text_color = "#333333"

    # Draw border
    border_margin = 40
    draw.rectangle(
        [border_margin, border_margin, width - border_margin, height - border_margin],
        outline=primary_color,
        width=10
    )
    # Inner border
    inner_margin = 55
    draw.rectangle(
        [inner_margin, inner_margin, width - inner_margin, height - inner_margin],
        outline=gold_color,
        width=2
    )

    # Load Fonts
    title_font = _get_font("PlayfairDisplay-Bold.ttf", 90)
    subtitle_font = _get_font("Roboto-Regular.ttf", 40)
    name_font = _get_font("PlayfairDisplay-Bold.ttf", 120)
    course_font = _get_font("PlayfairDisplay-Bold.ttf", 60)
    small_font = _get_font("Roboto-Regular.ttf", 25)

    # Helper for centered text
    def draw_centered_text(y: int, text: str, font: ImageFont.FreeTypeFont, fill: str):
        # Use textbbox instead of deprecated textsize
        bbox = draw.textbbox((0, 0), text, font=font)
        text_width = bbox[2] - bbox[0]
        x = (width - text_width) / 2
        draw.text((x, y), text, fill=fill, font=font)

    # Add text
    draw_centered_text(150, "CERTIFICATE OF COMPLETION", title_font, primary_color)
    draw_centered_text(280, "This is to certify that", subtitle_font, text_color)
    
    draw_centered_text(400, student_name, name_font, accent_color)
    
    # Underline name
    bbox = draw.textbbox((0, 0), student_name, font=name_font)
    text_width = bbox[2] - bbox[0]
    x_start = (width - text_width) / 2
    draw.line([(x_start - 50, 540), (x_start + text_width + 50, 540)], fill=gold_color, width=4)

    draw_centered_text(600, "has successfully completed the course", subtitle_font, text_color)
    draw_centered_text(700, course_name, course_font, primary_color)

    # Signatures and Date
    date_label = f"Date: {date_str}"
    id_label = f"Certificate ID: {certificate_id}"
    
    # Left side (Date)
    draw.text((250, 950), date_label, fill=text_color, font=subtitle_font)
    draw.line([(250, 1000), (550, 1000)], fill=text_color, width=2)
    
    # Right side (Signature)
    draw.text((width - 600, 950), "Instructor Signature", fill=text_color, font=subtitle_font)
    draw.line([(width - 650, 1000), (width - 250, 1000)], fill=text_color, width=2)
    
    # Bottom Center (ID)
    draw_centered_text(1100, id_label, small_font, "#666666")
    draw_centered_text(1150, "Verify at: PyLearn.com/verify", small_font, "#666666")

    # Save to BytesIO
    img_byte_arr = io.BytesIO()
    img.save(img_byte_arr, format='JPEG', quality=90)
    return img_byte_arr.getvalue()

def upload_certificate_to_cloudinary(image_bytes: bytes, certificate_id: str) -> str:
    """Uploads the certificate bytes to Cloudinary and returns the secure URL."""
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
    """Generates a certificate and uploads it, returning the URL."""
    date_str = datetime.datetime.now().strftime("%B %d, %Y")
    image_bytes = generate_certificate_image(student_name, course_name, date_str, certificate_id)
    return upload_certificate_to_cloudinary(image_bytes, certificate_id)
