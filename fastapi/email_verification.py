from datetime import datetime, timedelta
from sendgrid.helpers.mail import Mail, Email, To, Content
import jwt # To generate unique key
import sendgrid

SENDGRID_API_KEY = "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"
EXPIRATION = datetime.now() + timedelta(hours=1)
SECRET_KEY = "JasonSuperStrong"

def generate_verification_token(email: str): # for email verification
    expiration = EXPIRATION
    payload = {"email": email, "exp": expiration}
    token = jwt.encode(payload, SECRET_KEY, algorithm="HS256")
    return token


    
def send_verification_email(email: str, token: str):
    # Construct the verification URL
    verification_url = f"https://cefa-2407-4d00-3c00-9143-1da0-725-4097-7a67.ngrok-free.app/verify/{token}"
    
    subject = "Please verify your Email Address"
    body = f"Click the following link to verify your email address: {verification_url}"
    from_email = Email("your-email@gmail.com") # SendGrid Single Sender Verification not done yet
    to_email = To(email)
    content = Content("text/plain", body)
    
    # Send email using SendGrid
    sg = sendgrid.SendGridAPIClient(api_key=SENDGRID_API_KEY)
    mail = Mail(from_email, to_email, subject, content)
    response = sg.send(mail)
    print(f"Email sent! Status Code: {response.status_code}")
    
def decode_verification_token(token):
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=["HS256"])
        return payload["email"]
    except jwt.ExpiredSignatureError:
        raise ValueError("Verification token expired")
    except jwt.InvalidTokenError:
        raise ValueError("Invalid token")