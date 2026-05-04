from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
import uuid
from app.database import get_db, CrowdReport
from app.models import CrowdReportRequest, CrowdReportResponse

router = APIRouter()

@router.post("/", response_model=CrowdReportResponse)
def submit_report(req: CrowdReportRequest, db: Session = Depends(get_db)):
    report = CrowdReport(
        id=str(uuid.uuid4()),
        **req.model_dump(),
        status="pending"
    )
    db.add(report)
    db.commit()
    db.refresh(report)
    return report

@router.get("/")
def get_reports(db: Session = Depends(get_db)):
    return db.query(CrowdReport).all()
