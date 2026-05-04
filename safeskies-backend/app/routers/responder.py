from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.database import get_db, Alert
from app.models import ResponderAction

router = APIRouter()

@router.patch("/{alert_id}")
def update_alert(alert_id: str, action: ResponderAction, db: Session = Depends(get_db)):
    alert = db.query(Alert).filter(Alert.id == alert_id).first()
    if alert:
        alert.status = action.status
        db.commit()
        return {"status": "updated"}
    return {"error": "not found"}
