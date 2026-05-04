from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime

class ZoneBase(BaseModel):
    id: str
    name: str
    lat: float
    lon: float
    elevation_m: float

class ZoneResponse(ZoneBase):
    class Config:
        from_attributes = True

class WeatherSnapshotBase(BaseModel):
    zone_id: str
    precip_mm: float
    wind_kph: float
    risk_score: float
    hazard_type: str

class AlertResponse(BaseModel):
    id: str
    zone_ids: str
    severity: str
    issued_at: datetime
    expires_at: Optional[datetime] = None
    message_en: str
    status: str

    class Config:
        from_attributes = True

class SubscriptionRequest(BaseModel):
    phone: Optional[str] = None
    fcm_token: Optional[str] = None
    lat: float
    lon: float
    language: str = "en"

class CrowdReportRequest(BaseModel):
    lat: float
    lon: float
    type: str
    severity: str

class CrowdReportResponse(CrowdReportRequest):
    id: str
    status: str
    
    class Config:
        from_attributes = True

class ResponderAction(BaseModel):
    status: str
