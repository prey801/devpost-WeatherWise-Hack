import uuid
import datetime
from app.database import SessionLocal, Alert, Subscription
from app.services.sms_service import send_sms
from app.socket import sio

def dispatch_alert(zone, snapshot):
    db = SessionLocal()
    try:
        # Deduplication: do not re-send if alert exists < 2 hours
        cutoff = datetime.datetime.now(datetime.timezone.utc) - datetime.timedelta(hours=2)
        recent_alert = db.query(Alert).filter(
            Alert.zone_ids == zone.id,
            Alert.issued_at >= cutoff
        ).first()
        
        if recent_alert:
            return
            
        alert = Alert(
            id=f"alrt_{uuid.uuid4().hex[:8]}",
            zone_ids=zone.id,
            severity="HIGH" if snapshot.risk_score < 0.8 else "CRITICAL",
            message_en=f"ALERT: High risk of {snapshot.hazard_type} in {zone.name}. Please take precautions.",
        )
        db.add(alert)
        db.commit()
        
        subs = db.query(Subscription).all()
        phones = [s.phone for s in subs if s.phone]
        if phones:
            send_sms(phones, alert.message_en)
            
        import asyncio
        try:
            # Create a new event loop for this thread if one doesn't exist
            loop = asyncio.new_event_loop()
            asyncio.set_event_loop(loop)
            loop.run_until_complete(sio.emit('new_alert', {
                "id": alert.id,
                "zone_ids": alert.zone_ids,
                "severity": alert.severity,
                "message": alert.message_en
            }))
            loop.close()
        except Exception as e:
            print("Websocket emit failed:", e)

    finally:
        db.close()
