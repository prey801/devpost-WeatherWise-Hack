def calculate_risk_score(precip_mm: float, wind_kph: float, humidity_pct: float):
    score = 0.0
    if precip_mm > 10:
        score += 0.3
    if precip_mm > 30:
        score += 0.3
    if wind_kph > 50:
        score += 0.2
    if humidity_pct > 85 and precip_mm > 5:
        score += 0.1
        
    label = "LOW"
    hazard_type = "none"
    
    if score >= 0.8:
        label = "CRITICAL"
        hazard_type = "flood" if precip_mm > 30 else "cyclone"
    elif score >= 0.6:
        label = "HIGH"
        hazard_type = "flood" if precip_mm > 10 else "wind_damage"
    elif score >= 0.3:
        label = "MEDIUM"
        
    return {
        "score": min(score, 1.0),
        "label": label,
        "hazard_type": hazard_type
    }
