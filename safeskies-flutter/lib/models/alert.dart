class Alert {
  final String id;
  final String zoneIds;  // comma-separated zone IDs
  final String severity;  // "LOW", "MEDIUM", "HIGH", "CRITICAL"
  final String messageEn;
  final String status;    // "active", "inactive"
  final DateTime issuedAt;
  final DateTime? expiresAt;

  Alert({
    required this.id,
    required this.zoneIds,
    required this.severity,
    required this.messageEn,
    required this.status,
    required this.issuedAt,
    this.expiresAt,
  });

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      id: json['id'] ?? '',
      zoneIds: json['zone_ids'] ?? '',
      severity: json['severity'] ?? 'LOW',
      messageEn: json['message_en'] ?? '',
      status: json['status'] ?? 'active',
      issuedAt: DateTime.parse(json['issued_at'] ?? DateTime.now().toIso8601String()),
      expiresAt: json['expires_at'] != null 
          ? DateTime.parse(json['expires_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'zone_ids': zoneIds,
    'severity': severity,
    'message_en': messageEn,
    'status': status,
    'issued_at': issuedAt.toIso8601String(),
    'expires_at': expiresAt?.toIso8601String(),
  };

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  bool get isActive {
    return status == 'active' && !isExpired;
  }

  String get label => severity.toLowerCase();
}

class AlertsResponse {
  final List<Alert> alerts;

  AlertsResponse({
    required this.alerts,
  });

  factory AlertsResponse.fromJson(List<dynamic> json) {
    List<Alert> alerts = (json)
        .map((item) => Alert.fromJson(item as Map<String, dynamic>))
        .toList();
    return AlertsResponse(alerts: alerts);
  }

  Map<String, dynamic> toJson() => {
    'alerts': alerts.map((a) => a.toJson()).toList(),
  };
}
