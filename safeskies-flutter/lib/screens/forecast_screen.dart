import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:safeskies/providers/weather_provider.dart';
import 'package:safeskies/widgets/offline_banner.dart';
import 'package:safeskies/models/forecast.dart';

class ForecastScreen extends StatefulWidget {
  const ForecastScreen({Key? key}) : super(key: key);

  @override
  State<ForecastScreen> createState() => _ForecastScreenState();
}

class _ForecastScreenState extends State<ForecastScreen> {
  @override\n  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather Data'),
        elevation: 0,
      ),
      body: Consumer<WeatherProvider>(
        builder: (context, weatherProvider, _) {
          return RefreshIndicator(
            onRefresh: () => weatherProvider.refreshData(),
            child: ListView(
              children: [
                // Offline banner
                if (!weatherProvider.isOnline)
                  OfflineBanner(
                    isExpired: weatherProvider.cacheExpired,
                  ),

                // Weather data list
                if (weatherProvider.forecast != null)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Zone Weather Status',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: weatherProvider.forecast!.snapshots.length,
                          itemBuilder: (context, index) {
                            final snapshot = weatherProvider.forecast!.snapshots[index];
                            return _WeatherSnapshotCard(snapshot: snapshot);
                          },
                        ),
                      ],
                    ),
                  )
                else if (weatherProvider.isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        weatherProvider.error ?? 'No weather data available',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
                      child: Text(
                        weatherProvider.error ?? 'No forecast data available',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _WeatherSnapshotCard extends StatelessWidget {
  final WeatherSnapshot snapshot;

  const _WeatherSnapshotCard({required this.snapshot});

  Color _getRiskColor() {
    switch (snapshot.riskLabel) {
      case 'critical':
        return Colors.deepOrange;
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  IconData _getWeatherIcon() {
    switch (snapshot.hazardType.toLowerCase()) {
      case 'flood':
        return Icons.water;
      case 'wind_damage':
        return Icons.air;
      case 'cyclone':
        return Icons.cloud_queue;
      default:
        return Icons.cloud;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(
          _getWeatherIcon(),
          color: _getRiskColor(),
        ),
        title: Text(
          snapshot.zoneId,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Precip: ${snapshot.precipMm.toStringAsFixed(1)}mm | Wind: ${snapshot.windKph.toStringAsFixed(0)} kph',
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              'Updated: ${_formatTime(snapshot.capturedAt)}',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getRiskColor().withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            snapshot.riskLabel.toUpperCase(),
            style: TextStyle(
              color: _getRiskColor(),
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return 'just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }
}
