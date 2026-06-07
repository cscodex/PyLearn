import resend
from app.core.config import settings

# Initialize Resend
if settings.RESEND_API_KEY:
    resend.api_key = settings.RESEND_API_KEY

async def send_password_reset_email(email_to: str, token: str) -> bool:
    """Send password reset email via Resend."""
    if not settings.RESEND_API_KEY:
        print(f"MOCK EMAIL: Sent password reset token {token} to {email_to}")
        return True
        
    try:
        reset_url = f"http://localhost:8000/reset-password?token={token}"
        html_content = f"""
        <html>
            <body>
                <h2>Reset Your PythonTutor Password</h2>
                <p>Click the link below to reset your password:</p>
                <a href="{reset_url}">Reset Password</a>
                <p>If you did not request this, please ignore this email.</p>
            </body>
        </html>
        """
        
        response = resend.Emails.send({
            "from": "PythonTutor <noreply@pythontutor.com>",
            "to": email_to,
            "subject": "Password Reset - PythonTutor",
            "html": html_content
        })
        return True
    except Exception as e:
        print(f"Error sending email: {str(e)}")
        return False
