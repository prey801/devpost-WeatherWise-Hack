import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:safeskies/models/forecast.dart';
import 'package:safeskies/models/alert.dart';
import 'package:safeskies/models/report.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  
  // Toggle this to true to use mock data for testing
  static const bool USE_MOCK = true;
  static const String BACKEND_URL = 'http://localhost:8000/v1';
  // For production, update to: static const String BACKEND_URL = 'https://api.safeskies.app/v1';

  late http.Client _httpClient;

  factory ApiService() {
    return _instance;
  }

  ApiService._internal() {
    _httpClient = http.Client();
  }

  // ==================== FORECAST ====================

  Future<ForecastResponse> getForecast() async {
    if (USE_MOCK) {
      return _mockGetForecast();
    }

    try {
      final response = await _httpClient.get(
        Uri.parse('$BACKEND_URL/forecast/'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as List<dynamic>;
        return ForecastResponse.fromJson(json);
      } else {
        throw Exception('Failed to fetch forecast: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching forecast: $e');
    }
  }

  // ==================== ALERTS ====================

  Future<AlertsResponse> getAlerts() async {
    if (USE_MOCK) {
      return _mockGetAlerts();
    }

    try {
      final response = await _httpClient.get(
        Uri.parse('$BACKEND_URL/alerts/active'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as List<dynamic>;
        return AlertsResponse.fromJson(json);
      } else {
        throw Exception('Failed to fetch alerts: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching alerts: $e');
    }
  }

  // ==================== REPORTS ====================

  Future<ReportResponse> submitReport(ReportRequest request) async {
    if (USE_MOCK) {
      return _mockSubmitReport(request);
    }

    try {
      final response = await _httpClient.post(
        Uri.parse('$BACKEND_URL/reports/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 201 || response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return ReportResponse.fromJson(json);
      } else {
        throw Exception('Failed to submit report: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error submitting report: $e');
    }
  }

  // ==================== NOTIFICATIONS ====================

  Future<void> subscribe(String phone, double lat, double lon, String fcmToken) async {
    if (USE_MOCK) {
      return _mockSubscribe(phone, lat, lon, fcmToken);
    }

    try {
      final body = {
        'phone': phone,
        'lat': lat,
        'lon': lon,
        'fcm_token': fcmToken,
        'language': 'en',
      };

      final response = await _httpClient.post(
        Uri.parse('$BACKEND_URL/alerts/subscribe'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to subscribe: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error subscribing: $e');
    }
  }

  // ==================== MOCK DATA ====================

  ForecastResponse _mockGetForecast() {
    final snapshots = <WeatherSnapshot>[
      WeatherSnapshot(
        id: 1,
        zoneId: 'KE-NBI-001',
        precipMm: 5.2,
        windKph: 15.0,
        riskScore: 0.35,
        hazardType: 'none',
        capturedAt: DateTime.now(),
      ),
      WeatherSnapshot(
        id: 2,
        zoneId: 'KE-MSA-001',
        precipMm: 12.5,
        windKph: 35.0,
        riskScore: 0.65,
        hazardType: 'flood',
        capturedAt: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
      WeatherSnapshot(
        id: 3,
        zoneId: 'KE-NBI-001',
        precipMm: 35.0,
        windKph: 55.0,
        riskScore: 0.85,
        hazardType: 'flood',
        capturedAt: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
    ];

    return ForecastResponse(snapshots: snapshots);
  }

  AlertsResponse _mockGetAlerts() {
    return AlertsResponse(
      alerts: [
        Alert(
          id: 'alert_high_001',
          zoneIds: 'KE-MSA-001',
          severity: 'HIGH',
          messageEn: 'SEVERE: Flash flood warning in coastal region. Avoid roads near rivers. Status: Active.',
          status: 'active',
          issuedAt: DateTime.now().subtract(const Duration(hours: 2)),
          expiresAt: DateTime.now().add(const Duration(hours: 6)),
        ),
        Alert(
          id: 'alert_medium_002',
          zoneIds: 'KE-NBI-001',
          severity: 'MEDIUM',
          messageEn: 'Strong winds expected (40-50 kph). Secure outdoor items and avoid elevated areas.',
          status: 'active',
          issuedAt: DateTime.now().subtract(const Duration(hours: 1)),
          expiresAt: DateTime.now().add(const Duration(hours: 12)),
        ),
        Alert(
          id: 'alert_low_003',
          zoneIds: 'KE-NBI-001,KE-MSA-001',
          severity: 'LOW',
          messageEn: 'Light rain expected in the evening. Humidity levels rising.',
          status: 'active',
          issuedAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(hours: 24)),
        ),
      ],
    );
  }

  ReportResponse _mockSubmitReport(ReportRequest request) {
    return ReportResponse(
      success: true,
      reportId: 'report_${DateTime.now().millisecondsSinceEpoch}',
      message: 'Thank you for reporting! Your hazard report helps the SafeSkies community stay informed.',
    );
  }

  void _mockSubscribe(String phone, double lat, double lon, String fcmToken) {
    // Mock subscription - simulates successful registration
  }
}
