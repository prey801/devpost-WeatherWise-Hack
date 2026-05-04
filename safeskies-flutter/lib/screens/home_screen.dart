import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:safeskies/providers/weather_provider.dart';
import 'package:safeskies/widgets/risk_banner.dart';
import 'package:safeskies/widgets/offline_banner.dart';
import 'package:safeskies/widgets/alert_card.dart';
import 'package:safeskies/models/alert.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late MapController _mapController;
  bool _showAlertList = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<WeatherProvider>(
        builder: (context, weatherProvider, _) {
          return Stack(
            children: [
              // Map
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: weatherProvider.userLocation ?? const LatLng(0, 0),
                  initialZoom: 12,
                  minZoom: 2,
                  maxZoom: 18,
                ),
                children: [
                  // OSM Tiles
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.safeskies.app',
                  ),
                  // Risk zone circles
                  if (weatherProvider.userLocation != null)
                    CircleLayer(
                      circles: [
                        CircleMarker(
                          point: weatherProvider.userLocation!,
                          radius: 5,
                          color: Colors.blue.withOpacity(0.7),
                          borderStrokeWidth: 2,
                          borderColor: Colors.blue,
                        ),
                        // Risk zone based on highest alert
                        if (weatherProvider.alerts != null &&
                            weatherProvider.alerts!.alerts.isNotEmpty)
                          CircleMarker(
                            point: weatherProvider.userLocation!,
                            radius: 80,
                            color: _getRiskZoneColor(weatherProvider.riskLevel)
                                .withOpacity(0.1),
                            borderStrokeWidth: 2,
                            borderColor:
                                _getRiskZoneColor(weatherProvider.riskLevel),
                          ),
                      ],
                    ),
                  // Alert markers
                  if (weatherProvider.alerts != null)
                    MarkerLayer(
                      markers: weatherProvider.alerts!.alerts
                          .map(
                            (alert) => Marker(
                              point: LatLng(alert.lat, alert.lon),
                              width: 40,
                              height: 40,
                              child: GestureDetector(
                                onTap: () => _showAlertDetail(alert),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: _getAlertColor(alert.label),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _getAlertColor(alert.label)
                                            .withOpacity(0.5),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.warning,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                ],
              ),

              // Risk Banner at top
              if (!_showAlertList)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    child: Column(
                      children: [
                        if (!weatherProvider.isOnline)
                          OfflineBanner(
                            lastUpdated: await _getLastUpdated(),
                            isExpired: weatherProvider.cacheExpired,
                          ),
                        RiskBanner(
                          riskLabel: weatherProvider.riskLevel,
                          message: weatherProvider.riskMessage,
                        ),
                      ],
                    ),
                  ),
                ),

              // Alert list slide-up
              if (_showAlertList && weatherProvider.alerts != null)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 12),
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Active Alerts',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 300,
                          child: ListView.builder(
                            itemCount: weatherProvider.alerts!.alerts.length,
                            itemBuilder: (context, index) {
                              final alert = weatherProvider.alerts!.alerts[index];
                              return AlertCard(alert: alert);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // FAB to toggle alert list
              Positioned(
                bottom: 20,
                right: 20,
                child: FloatingActionButton(
                  onPressed: () {
                    setState(() {
                      _showAlertList = !_showAlertList;
                    });
                  },
                  child: Icon(_showAlertList ? Icons.close : Icons.list),
                ),
              ),

              // Refresh button
              if (weatherProvider.isLoading)
                const Positioned(
                  top: 100,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: Consumer<WeatherProvider>(
        builder: (context, weatherProvider, _) {
          return FloatingActionButton.extended(
            onPressed: () async {
              await context.read<WeatherProvider>().refreshData();
            },
            label: const Text('Refresh'),
            icon: const Icon(Icons.refresh),
          );
        },
      ),
    );
  }

  Color _getRiskZoneColor(String level) {
    switch (level.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  Color _getAlertColor(String level) {
    switch (level.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  void _showAlertDetail(Alert alert) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${alert.label.toUpperCase()} Alert'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(alert.message),
            const SizedBox(height: 12),
            Text(
              'Radius: ${alert.radiusKm.toStringAsFixed(1)}km',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(
              'Location: ${alert.lat.toStringAsFixed(3)}, ${alert.lon.toStringAsFixed(3)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<DateTime?> _getLastUpdated() async {
    // This would come from cache service - simplified for now
    return null;
  }
}
