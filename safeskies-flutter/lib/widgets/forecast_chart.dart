import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:safeskies/models/forecast.dart';

class ForecastChart extends StatelessWidget {
  final List<Forecast> forecasts;

  const ForecastChart({
    Key? key,
    required this.forecasts,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (forecasts.isEmpty) {
      return const Center(
        child: Text('No forecast data available'),
      );
    }

    // Create line data for precipitation
    final spots = <FlSpot>[];
    for (int i = 0; i < forecasts.length; i++) {
      spots.add(
        FlSpot(i.toDouble(), forecasts[i].precipMm),
      );
    }

    final maxPrecip = forecasts.map((f) => f.precipMm).reduce((a, b) => a > b ? a : b);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '24-Hour Precipitation Forecast',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index % 4 == 0 && index < forecasts.length) {
                            return Text(
                              '${forecasts[index].hourOffset}h',
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}mm',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                        reservedSize: 40,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withOpacity(0.2),
                      ),
                    ),
                  ],
                  minY: 0,
                  maxY: (maxPrecip + 2).toDouble(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
