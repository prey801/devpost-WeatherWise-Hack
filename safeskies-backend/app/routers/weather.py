from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.database import get_db, WeatherSnapshot

router = APIRouter()

@router.get("/")
def get_forecast(db: Session = Depends(get_db)):
    snapshots = db.query(WeatherSnapshot).order_by(WeatherSnapshot.captured_at.desc()).limit(100).all()
    return snapshots
