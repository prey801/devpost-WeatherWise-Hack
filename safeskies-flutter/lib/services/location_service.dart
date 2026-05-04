import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();

  factory LocationService() {
    return _instance;
  }

  LocationService._internal();

  Future<bool> requestPermission() async {
    final permission = await Geolocator.requestPermission();
    return permission == LocationPermission.granted ||
           permission == LocationPermission.whileInUse;
  }

  Future<bool> hasPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.granted ||
           permission == LocationPermission.whileInUse;
  }

  Future<LatLng?> getCurrentLocation() async {
    try {
      final hasPermissionGrant = await hasPermission();
      if (!hasPermissionGrant) {
        final granted = await requestPermission();
        if (!granted) return null;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      return null;
    }
  }

  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  Stream<LatLng> getLocationStream() async* {
    try {
      final hasPermissionGrant = await hasPermission();
      if (!hasPermissionGrant) {
        final granted = await requestPermission();
        if (!granted) return;
      }

      await for (final position in Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // Update every 10 meters
        ),
      )) {
        yield LatLng(position.latitude, position.longitude);
      }
    } catch (e) {
      // Handle error
    }
  }

  double calculateDistance(LatLng point1, LatLng point2) {
    final Distance distance = Distance();
    return distance.as(LengthUnit.kilometer, point1, point2);
  }
}
