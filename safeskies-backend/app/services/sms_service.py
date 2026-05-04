import os
import africastalking

USERNAME = os.getenv("AFRICAS_TALKING_USERNAME", "sandbox")
API_KEY = os.getenv("AFRICAS_TALKING_KEY", "dummy_key")

africastalking.initialize(USERNAME, API_KEY)
sms = africastalking.SMS

def send_sms(phone_numbers, message):
    if not phone_numbers:
        return
    try:
        response = sms.send(message, phone_numbers)
        print("SMS sent:", response)
    except Exception as e:
        print("Encountered an error while sending SMS:", str(e))
