from sqlalchemy import create_engine, Column, Integer, String, Float, DateTime, BigInteger, ForeignKey
from sqlalchemy.orm import declarative_base, sessionmaker
from sqlalchemy.pool import StaticPool
import os
from datetime import datetime, timezone

def get_utc_now():
    return datetime.now(timezone.utc)

DATABASE_URL = os.environ.get("DATABASE_URL", "sqlite:///./safeskies.db")

engine = create_engine(
    DATABASE_URL,
    connect_args={"check_same_thread": False} if DATABASE_URL.startswith("sqlite") else {},
    poolclass=StaticPool if DATABASE_URL.startswith("sqlite") else None
)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

class Zone(Base):
    __tablename__ = "zones"
    id = Column(String, primary_key=True, index=True)
    name = Column(String)
    lat = Column(Float)
    lon = Column(Float)
    elevation_m = Column(Float)

class WeatherSnapshot(Base):
    __tablename__ = "weather_snapshots"
    id = Column(BigInteger, primary_key=True, autoincrement=True, index=True)
    zone_id = Column(String, ForeignKey("zones.id"))
    captured_at = Column(DateTime, default=get_utc_now)
    precip_mm = Column(Float)
    wind_kph = Column(Float)
    risk_score = Column(Float)
    hazard_type = Column(String)

class Alert(Base):
    __tablename__ = "alerts"
    id = Column(String, primary_key=True, index=True)
    zone_ids = Column(String)
    severity = Column(String)
    issued_at = Column(DateTime, default=get_utc_now)
    expires_at = Column(DateTime, nullable=True)
    message_en = Column(String)
    status = Column(String, default="active")

class Subscription(Base):
    __tablename__ = "subscriptions"
    id = Column(BigInteger, primary_key=True, autoincrement=True, index=True)
    phone = Column(String, index=True, nullable=True)
    fcm_token = Column(String, nullable=True)
    lat = Column(Float)
    lon = Column(Float)
    language = Column(String, default="en")

class CrowdReport(Base):
    __tablename__ = "crowd_reports"
    id = Column(String, primary_key=True, index=True)
    lat = Column(Float)
    lon = Column(Float)
    type = Column(String)
    severity = Column(String)
    status = Column(String, default="pending")

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
