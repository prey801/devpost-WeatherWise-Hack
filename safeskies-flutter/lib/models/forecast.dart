class WeatherSnapshot {
  final int id;
  final String zoneId;
  final double precipMm;
  final double windKph;
  final double riskScore;
  final String hazardType;
  final DateTime capturedAt;

  WeatherSnapshot({
    required this.id,
    required this.zoneId,
    required this.precipMm,
    required this.windKph,
    required this.riskScore,
    required this.hazardType,
    required this.capturedAt,
  });

  factory WeatherSnapshot.fromJson(Map<String, dynamic> json) {
    return WeatherSnapshot(
      id: json['id'] ?? 0,
      zoneId: json['zone_id'] ?? '',
      precipMm: (json['precip_mm'] ?? 0).toDouble(),
      windKph: (json['wind_kph'] ?? 0).toDouble(),
      riskScore: (json['risk_score'] ?? 0).toDouble(),
      hazardType: json['hazard_type'] ?? 'none',
      capturedAt: DateTime.parse(json['captured_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'zone_id': zoneId,
    'precip_mm': precipMm,
    'wind_kph': windKph,
    'risk_score': riskScore,
    'hazard_type': hazardType,
    'captured_at': capturedAt.toIso8601String(),
  };

  String get riskLabel {
    if (riskScore >= 0.8) return 'critical';
    if (riskScore >= 0.6) return 'high';
    if (riskScore >= 0.3) return 'medium';
    return 'low';
  }
}

class ForecastResponse {
  final List<WeatherSnapshot> snapshots;

  ForecastResponse({
    required this.snapshots,
  });

  factory ForecastResponse.fromJson(List<dynamic> json) {
    List<WeatherSnapshot> snapshots = (json)
        .map((item) => WeatherSnapshot.fromJson(item as Map<String, dynamic>))
        .toList();
    return ForecastResponse(snapshots: snapshots);
  }

  Map<String, dynamic> toJson() => {
    'snapshots': snapshots.map((s) => s.toJson()).toList(),
  };
}
