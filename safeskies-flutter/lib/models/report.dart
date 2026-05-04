class CrowdReport {
  final String id;
  final String hazardType; // "flood", "wind_damage", "road_blocked", "other"
  final String severity; // "low", "medium", "high"
  final String? description;
  final double lat;
  final double lon;
  final DateTime submittedAt;
  final String? userId;

  CrowdReport({
    required this.id,
    required this.hazardType,
    required this.severity,
    this.description,
    required this.lat,
    required this.lon,
    required this.submittedAt,
    this.userId,
  });

  factory CrowdReport.fromJson(Map<String, dynamic> json) {
    return CrowdReport(
      id: json['id'] ?? '',
      hazardType: json['hazard_type'] ?? 'other',
      severity: json['severity'] ?? 'low',
      description: json['description'],
      lat: (json['lat'] ?? 0).toDouble(),
      lon: (json['lon'] ?? 0).toDouble(),
      submittedAt: DateTime.parse(json['submitted_at'] ?? DateTime.now().toIso8601String()),
      userId: json['user_id'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'hazard_type': hazardType,
    'severity': severity,
    'description': description,
    'lat': lat,
    'lon': lon,
    'submitted_at': submittedAt.toIso8601String(),
    'user_id': userId,
  };
}

class ReportRequest {
  final double lat;
  final double lon;
  final String type;  // "flood", "wind_damage", "road_blocked", "other"
  final String severity;  // "low", "medium", "high"

  ReportRequest({
    required this.lat,
    required this.lon,
    required this.type,
    required this.severity,
  });

  Map<String, dynamic> toJson() => {
    'lat': lat,
    'lon': lon,
    'type': type,
    'severity': severity,
  };
}

class ReportResponse {
  final bool success;
  final String? reportId;
  final String? message;

  ReportResponse({
    required this.success,
    this.reportId,
    this.message,
  });

  factory ReportResponse.fromJson(Map<String, dynamic> json) {
    return ReportResponse(
      success: json['success'] ?? false,
      reportId: json['report_id'],
      message: json['message'],
    );
  }
}
