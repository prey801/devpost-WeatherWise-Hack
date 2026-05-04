import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:safeskies/providers/weather_provider.dart';
import 'package:safeskies/services/location_service.dart';
import 'package:safeskies/models/report.dart';
import 'package:safeskies/services/api_service.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({Key? key}) : super(key: key);

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();

  String? _selectedHazardType;
  String? _selectedSeverity;
  LatLng? _reportLocation;
  bool _isSubmitting = false;
  String? _successMessage;

  final List<String> _hazardTypes = [
    'Flood',
    'Wind Damage',
    'Road Blocked',
    'Other',
  ];

  final List<String> _severities = ['Low', 'Medium', 'High'];

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    final locationService = LocationService();
    final location = await locationService.getCurrentLocation();
    if (location != null) {
      setState(() {
        _reportLocation = location;
      });
    }
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;
    if (_reportLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location not available. Please enable GPS.'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final request = ReportRequest(
        type: _selectedHazardType!.toLowerCase().replaceAll(' ', '_'),
        severity: _selectedSeverity!.toLowerCase(),
        lat: _reportLocation!.latitude,
        lon: _reportLocation!.longitude,
      );

      final apiService = ApiService();
      final response = await apiService.submitReport(request);

      if (response.success) {
        setState(() {
          _successMessage = response.message ??
              'Thank you for reporting! Your report helps others stay safe.';
        });

        // Reset form
        _formKey.currentState!.reset();
        _descriptionController.clear();
        _selectedHazardType = null;
        _selectedSeverity = null;

        // Show success for 3 seconds then reset
        await Future.delayed(const Duration(seconds: 3));
        setState(() => _successMessage = null);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response.message ?? 'Failed to submit report. Please try again.',
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Hazard'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Success message
              if (_successMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    border: Border.all(color: Colors.green),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _successMessage!,
                    style: TextStyle(color: Colors.green[700]),
                  ),
                ),
              if (_successMessage != null) const SizedBox(height: 16),

              // Hazard Type Selector
              const Text(
                'Hazard Type',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedHazardType,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  hintText: 'Select hazard type',
                ),
                items: _hazardTypes
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() => _selectedHazardType = value);
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a hazard type';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Severity Selector
              const Text(
                'Severity',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedSeverity,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  hintText: 'Select severity',
                ),
                items: _severities
                    .map((severity) => DropdownMenuItem(
                          value: severity,
                          child: Text(severity),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() => _selectedSeverity = value);
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select severity';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Description
              const Text(
                'Description (Optional)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  hintText: 'Provide additional details...',
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 24),

              // Location display
              if (_reportLocation != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Report Location',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_reportLocation!.latitude.toStringAsFixed(4)}, ${_reportLocation!.longitude.toStringAsFixed(4)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                )
              else
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'Acquiring location...',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                ),
              const SizedBox(height: 24),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitReport,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Submit Report'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }
}
