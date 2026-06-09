import os
import io
import cloudinary.uploader
from PIL import Image, ImageDraw, ImageFont
import datetime
import math

BASE_DIR = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
ASSETS_DIR = os.path.join(BASE_DIR, "assets")
FONTS_DIR = os.path.join(ASSETS_DIR, "fonts")

def _get_font(font_name: str, size: int) -> ImageFont.FreeTypeFont:
    font_path = os.path.join(FONTS_DIR, font_name)
    try:
        return ImageFont.truetype(font_path, size)
    except Exception:
        return ImageFont.load_default()

def _draw_seal(draw, center_x, center_y, radius):
    """Draws a premium looking gold seal."""
    # Ribbons
    draw.polygon([
        (center_x - 30, center_y + radius - 10),
        (center_x - 80, center_y + radius + 150),
        (center_x, center_y + radius + 120),
    ], fill="#B45309")
    draw.polygon([
        (center_x + 30, center_y + radius - 10),
        (center_x + 80, center_y + radius + 150),
        (center_x, center_y + radius + 120),
    ], fill="#B45309")

    # Outer jagged edge (star-like)
    points = []
    num_points = 40
    for i in range(num_points * 2):
        r = radius + (10 if i % 2 == 0 else -10)
        angle = i * (math.pi / num_points)
        x = center_x + r * math.cos(angle)
        y = center_y + r * math.sin(angle)
        points.append((x, y))
    draw.polygon(points, fill="#D97706") # Gold
    
    # Inner circles
    draw.ellipse((center_x - radius + 10, center_y - radius + 10, center_x + radius - 10, center_y + radius - 10), outline="#FBBF24", width=4)
    draw.ellipse((center_x - radius + 18, center_y - radius + 18, center_x + radius - 18, center_y + radius - 18), fill="#F59E0B")
    
    # Seal text
    seal_font = _get_font("Roboto-Regular.ttf", 28)
    bbox = draw.textbbox((0, 0), "OFFICIAL", font=seal_font)
    draw.text((center_x - (bbox[2]-bbox[0])/2, center_y - 20), "OFFICIAL", fill="#FFFFFF", font=seal_font)
    bbox = draw.textbbox((0, 0), "SEAL", font=seal_font)
    draw.text((center_x - (bbox[2]-bbox[0])/2, center_y + 10), "SEAL", fill="#FFFFFF", font=seal_font)


def generate_certificate_image(student_name: str, course_name: str, date_str: str, certificate_id: str) -> bytes:
    # A4 dimensions in pixels at 300 DPI
    width, height = 3508, 2480
    img = Image.new('RGB', (width, height), color='#FDFBF7') # Off-white parchment color
    draw = ImageDraw.Draw(img)

    primary_color = "#0F172A" # Dark Slate
    accent_color = "#3730A3"  # Deep Indigo
    gold_color = "#B45309"    # Dark Gold
    text_color = "#334155"    # Slate Gray
    light_text = "#64748B"

    # 1. Complex Borders
    draw.rectangle([80, 80, width - 80, height - 80], outline=primary_color, width=20)
    draw.rectangle([110, 110, width - 110, height - 110], outline=gold_color, width=6)
    draw.rectangle([130, 130, width - 130, height - 130], outline=primary_color, width=2)
    
    # Corner accents
    for x in [80, width-80-100]:
        for y in [80, height-80-100]:
            draw.rectangle([x, y, x+100, y+100], fill=primary_color)
            draw.rectangle([x+10, y+10, x+90, y+90], outline=gold_color, width=4)

    # 2. Fonts
    title_font_size = 350
    subtitle_font_size = 150
    name_font = _get_font("GreatVibes-Regular.ttf", 550)
    course_font_size = 300
    signature_font = _get_font("PinyonScript-Regular.ttf", 200)
    small_font = _get_font("Roboto-Regular.ttf", 90)

    def draw_centered_text(y: int, text: str, font_name: str, base_size: int, fill: str, max_width: int = width - 400):
        # Auto-scale font if too wide
        size = base_size
        font = _get_font(font_name, size)
        bbox = draw.textbbox((0, 0), text, font=font)
        while (bbox[2] - bbox[0]) > max_width and size > 20:
            size -= 5
            font = _get_font(font_name, size)
            bbox = draw.textbbox((0, 0), text, font=font)
        
        text_width = bbox[2] - bbox[0]
        x = (width - text_width) / 2
        draw.text((x, y), text, fill=fill, font=font)

    def draw_wrapped_centered_text(y: int, text: str, font_name: str, size: int, fill: str, max_width: int = width - 400):
        font = _get_font(font_name, size)
        words = text.split()
        lines = []
        current_line = []
        for word in words:
            test_line = ' '.join(current_line + [word])
            bbox = draw.textbbox((0, 0), test_line, font=font)
            if (bbox[2] - bbox[0]) <= max_width:
                current_line.append(word)
            else:
                lines.append(' '.join(current_line))
                current_line = [word]
        if current_line:
            lines.append(' '.join(current_line))
        
        current_y = y
        for line in lines:
            bbox = draw.textbbox((0, 0), line, font=font)
            text_width = bbox[2] - bbox[0]
            text_height = bbox[3] - bbox[1]
            x = (width - text_width) / 2
            draw.text((x, current_y), line, fill=fill, font=font)
            current_y += text_height + 40

    # 3. Typography & Layout
    draw_centered_text(250, "CERTIFICATE", "PlayfairDisplay-Bold.ttf", title_font_size + 100, primary_color)
    draw_centered_text(600, "OF ACHIEVEMENT", "PlayfairDisplay-Bold.ttf", title_font_size - 100, primary_color)
    
    draw_centered_text(900, "THIS IS PROUDLY PRESENTED TO", "Roboto-Regular.ttf", subtitle_font_size, gold_color)
    
    # Student Name
    draw_centered_text(1100, student_name, "GreatVibes-Regular.ttf", 550, accent_color)
    
    # Separator Line
    draw.line([(width/2 - 900, 1550), (width/2 + 900, 1550)], fill=gold_color, width=8)

    # Description
    description = "In recognition of their outstanding performance and successful completion of the requirements for the following program:"
    draw_wrapped_centered_text(1650, description, "Roboto-Regular.ttf", subtitle_font_size, text_color)
    
    # Course Name
    draw_centered_text(1950, course_name, "PlayfairDisplay-Bold.ttf", course_font_size, primary_color)

    # 4. Footer & Signatures
    # Seal
    _draw_seal(draw, width/2, 2350, 180)

    # Date
    date_y = 2250
    bbox = draw.textbbox((0, 0), date_str, font=signature_font)
    date_width = bbox[2] - bbox[0]
    draw.text((600 - date_width/2, date_y - 120), date_str, fill=primary_color, font=signature_font)
    draw.line([(350, date_y + 80), (850, date_y + 80)], fill=primary_color, width=6)
    draw.text((550, date_y + 110), "Date", fill=light_text, font=small_font)
    
    # Signature
    sig_y = 2250
    sig_str = "PyLearn Director"
    bbox = draw.textbbox((0, 0), sig_str, font=signature_font)
    sig_width = bbox[2] - bbox[0]
    draw.text((width - 600 - sig_width/2, sig_y - 120), sig_str, fill=primary_color, font=signature_font)
    draw.line([(width - 850, sig_y + 80), (width - 350, sig_y + 80)], fill=primary_color, width=6)
    draw.text((width - 680, sig_y + 110), "Instructor", fill=light_text, font=small_font)
    
    # Certificate ID at the very bottom
    draw_centered_text(2600, f"Certificate ID: {certificate_id}  |  Verify authenticity at pylearn.com/verify/{certificate_id}", "Roboto-Regular.ttf", 70, light_text)

    # 5. Export
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
    date_str = datetime.datetime.now().strftime("%B %d, %Y")
    image_bytes = generate_certificate_image(student_name, course_name, date_str, certificate_id)
    return upload_certificate_to_cloudinary(image_bytes, certificate_id)
