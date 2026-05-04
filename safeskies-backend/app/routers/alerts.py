from fastapi import APIRouter, Depends, Request, Form
from sqlalchemy.orm import Session
from app.database import get_db, Alert, Subscription
from app.models import SubscriptionRequest
from app.services.sms_service import send_sms

router = APIRouter()

@router.get("/active")
def get_active_alerts(db: Session = Depends(get_db)):
    return db.query(Alert).filter(Alert.status == "active").all()

@router.post("/subscribe")
def subscribe(req: SubscriptionRequest, db: Session = Depends(get_db)):
    sub = Subscription(**req.model_dump())
    db.add(sub)
    db.commit()
    db.refresh(sub)
    return {"status": "subscribed", "id": sub.id}

@router.post("/sms")
async def sms_webhook(
    request: Request,
    db: Session = Depends(get_db),
    sessionId: str = Form(None),
    phoneNumber: str = Form(...),
    networkCode: str = Form(None),
    serviceCode: str = Form(None),
    text: str = Form(...)
):
    text = text.strip().upper()
    if text == "WEATHER":
        reply = "Current risk level is LOW. No immediate hazards detected."
        # We could query WeatherSnapshot here if we wanted to be perfectly accurate for user location
    elif text == "HELP":
        reply = "Available commands: WEATHER (get forecast), STOP (unsubscribe), HELP (this message)"
    elif text == "STOP":
        db.query(Subscription).filter(Subscription.phone == phoneNumber).delete()
        db.commit()
        reply = "You have been unsubscribed from SafeSkies alerts."
    else:
        reply = "Send WEATHER for forecast or HELP for commands."
    
    send_sms([phoneNumber], reply)
    return {"status": "ok"}
