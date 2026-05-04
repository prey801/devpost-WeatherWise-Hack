import os
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from apscheduler.schedulers.background import BackgroundScheduler
import socketio

from app.database import Base, engine, get_db, Zone
from app.routers import weather, alerts, reports, responder
from app.services.ingestion import ingest_weather_data
from app.socket import sio

Base.metadata.create_all(bind=engine)

def seed_zones():
    db = next(get_db())
    if not db.query(Zone).first():
        zones = [
            Zone(id="KE-NBI-001", name="Nairobi Central", lat=-1.2921, lon=36.8219, elevation_m=1795),
            Zone(id="KE-MSA-001", name="Mombasa Island", lat=-4.0435, lon=39.6682, elevation_m=50),
        ]
        db.add_all(zones)
        db.commit()
    db.close()

scheduler = BackgroundScheduler()

@asynccontextmanager
async def lifespan(fastapi_app: FastAPI):
    seed_zones()
    scheduler.add_job(ingest_weather_data, id='ingest', replace_existing=True)
    scheduler.add_job(ingest_weather_data, 'interval', minutes=15)
    scheduler.start()
    yield
    scheduler.shutdown()

app = FastAPI(title="SafeSkies API", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

sio_app = socketio.ASGIApp(socketio_server=sio, other_asgi_app=app)

app.include_router(weather.router, prefix="/v1/forecast", tags=["Forecast"])
app.include_router(alerts.router, prefix="/v1/alerts", tags=["Alerts"])
app.include_router(reports.router, prefix="/v1/reports", tags=["Reports"])
app.include_router(responder.router, prefix="/v1/responder", tags=["Responder"])
