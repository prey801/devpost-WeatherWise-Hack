import httpx
from sqlalchemy.orm import Session
from app.database import SessionLocal, Zone, WeatherSnapshot
from app.services.scorer import calculate_risk_score

def ingest_weather_data():
    db = SessionLocal()
    try:
        zones = db.query(Zone).all()
        for zone in zones:
            url = f"https://api.open-meteo.com/v1/forecast?latitude={zone.lat}&longitude={zone.lon}&hourly=temperature_2m,precipitation,windspeed_10m,relativehumidity_2m&current_weather=true"
            response = httpx.get(url)
            if response.status_code == 200:
                data = response.json()
                hourly = data.get("hourly", {})
                if hourly and "precipitation" in hourly:
                    precip_mm = hourly["precipitation"][0]
                    wind_kph = hourly["windspeed_10m"][0]
                    humidity_pct = hourly["relativehumidity_2m"][0]
                    
                    score_data = calculate_risk_score(precip_mm, wind_kph, humidity_pct)
                    
                    snapshot = WeatherSnapshot(
                        zone_id=zone.id,
                        precip_mm=precip_mm,
                        wind_kph=wind_kph,
                        risk_score=score_data["score"],
                        hazard_type=score_data["hazard_type"]
                    )
                    db.add(snapshot)
                    db.commit()
                    
                    if score_data["score"] >= 0.6:
                        from app.services.push_service import dispatch_alert
                        dispatch_alert(zone, snapshot)
                        
    except Exception as e:
        print(f"Error ingesting weather: {e}")
    finally:
        db.close()
