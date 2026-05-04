import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:latlong2/latlong.dart';
import 'package:safeskies/models/forecast.dart';
import 'package:safeskies/models/alert.dart';
import 'package:safeskies/services/api_service.dart';
import 'package:safeskies/services/cache_service.dart';
import 'package:safeskies/services/location_service.dart';

class WeatherProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final CacheService _cacheService = CacheService();
  final LocationService _locationService = LocationService();
  final Connectivity _connectivity = Connectivity();

  // State
  LatLng? _userLocation;
  ForecastResponse? _forecast;
  AlertsResponse? _alerts;
  bool _isOnline = true;
  bool _isLoading = false;
  String? _error;
  bool _cacheExpired = false;

  // Getters
  LatLng? get userLocation => _userLocation;
  ForecastResponse? get forecast => _forecast;
  AlertsResponse? get alerts => _alerts;
  bool get isOnline => _isOnline;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get cacheExpired => _cacheExpired;

  // State flags
  bool get hasData => _forecast != null && _alerts != null;
  String get riskLevel {
    if (_alerts == null || _alerts!.alerts.isEmpty) return 'low';
    
    for (final alert in _alerts!.alerts) {
      if (alert.severity == 'CRITICAL') return 'critical';
      if (alert.severity == 'HIGH') return 'high';
    }
    for (final alert in _alerts!.alerts) {
      if (alert.severity == 'MEDIUM') return 'medium';
    }
    return 'low';
  }

  String get riskMessage {
    if (_alerts == null || _alerts!.alerts.isEmpty) {
      return 'No weather alerts in your area';
    }

    for (final alert in _alerts!.alerts) {
      if (alert.severity == 'CRITICAL' || alert.severity == 'HIGH') {
        return alert.messageEn;
      }
    }
    for (final alert in _alerts!.alerts) {
      if (alert.severity == 'MEDIUM') return alert.messageEn;
    }
    
    return _alerts!.alerts.first.messageEn;
  }

  Future<void> init() async {
    await _cacheService.init();
    _monitorConnectivity();
    await _loadUserLocation();
    await refreshData();
  }

  Future<void> refreshData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Fetch forecast and alerts in parallel
      final forecastFuture = _apiService.getForecast();
      final alertsFuture = _apiService.getAlerts();

      final results = await Future.wait([forecastFuture, alertsFuture]);
      
      _forecast = results[0] as ForecastResponse;
      _alerts = results[1] as AlertsResponse;

      // Cache the data if online
      if (_isOnline) {
        await _cacheService.setForecast(_forecast!);
        await _cacheService.setAlerts(_alerts!);
        await _cacheService.setLastUpdated();
        _cacheExpired = false;
      }
    } catch (e) {
      _error = 'Failed to fetch data: $e';

      // Fall back to cached data
      if (!_isOnline) {
        await _loadFromCache();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadUserLocation() async {
    final location = await _locationService.getCurrentLocation();
    if (location != null) {
      _userLocation = location;
      notifyListeners();
    }
  }

  Future<void> _loadFromCache() async {
    try {
      _forecast = await _cacheService.getForecast();
      _alerts = await _cacheService.getAlerts();
      _cacheExpired = await _cacheService.isCacheExpired();
    } catch (e) {
      _error = 'Could not load cached data: $e';
    }
    notifyListeners();
  }

  void _monitorConnectivity() {
    _connectivity.onConnectivityChanged.listen((result) {
      final wasOnline = _isOnline;
      _isOnline = result != ConnectivityResult.none;

      if (wasOnline && !_isOnline) {
        // Went offline - load from cache
        _loadFromCache();
      } else if (!wasOnline && _isOnline) {
        // Went online - refresh data
        refreshData();
      }

      notifyListeners();
    });
  }

  void updateUserLocation(LatLng location) {
    _userLocation = location;
    notifyListeners();
  }

  List<Alert> getAlertsForLocation(LatLng location, double radiusKm) {
    if (_alerts == null) return [];

    final Distance distance = Distance();
    return _alerts!.alerts.where((alert) {
      final alertLocation = LatLng(alert.lat, alert.lon);
      final distKm = distance.as(LengthUnit.kilometer, location, alertLocation);
      return distKm <= (alert.radiusKm + radiusKm) && !alert.isExpired;
    }).toList();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
