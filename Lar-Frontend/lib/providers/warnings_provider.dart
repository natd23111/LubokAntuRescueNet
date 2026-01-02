import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import '../models/warning.dart';

class WarningsProvider extends ChangeNotifier {
  List<Warning> _warnings = [];
  bool _isLoading = false;
  String? _error;
  Position? _currentPosition;
  bool useDemo = false; // Toggle for demo mode

  // Getters
  List<Warning> get warnings => _warnings;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Position? get currentPosition => _currentPosition;

  int get activeWarningsCount => _warnings.length;
  int get highSeverityCount => _warnings.where((w) => w.severity == 'high').length;
  int get mediumSeverityCount => _warnings.where((w) => w.severity == 'medium').length;
  int get lowSeverityCount => _warnings.where((w) => w.severity == 'low').length;

  WarningsProvider() {
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    try {
      final hasPermission = await _checkLocationPermission();
      if (hasPermission) {
        await _getCurrentLocation();
        await fetchWarnings();
      }
    } catch (e) {
      _error = 'Failed to initialize location: $e';
      notifyListeners();
    }
  }

  Future<bool> _checkLocationPermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _error = 'Location services are disabled. Please enable them.';
        notifyListeners();
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        _error = 'Location permission was denied.';
        notifyListeners();
        return false;
      }

      if (permission == LocationPermission.deniedForever) {
        _error = 'Location permissions are permanently denied. Open app settings to enable.';
        notifyListeners();
        return false;
      }

      return permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    } catch (e) {
      _error = 'Error checking location permission: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('Location request timed out after 15 seconds'),
      );
      notifyListeners();
    } catch (e) {
      _error = 'Error getting location: $e';
      notifyListeners();
    }
  }

  Future<void> fetchWarnings() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Get current location if not already available
      if (_currentPosition == null) {
        await _getCurrentLocation();
      }

      // Use demo data if toggle is on
      if (useDemo) {
        _warnings = _generateDemoWarnings();
      } else {
        // Fetch from both APIs
        final weatherAlerts = await _fetchWeatherAlerts();
        final floodReports = await _fetchFloodReports();

        // Merge both sources
        _warnings = [...weatherAlerts, ...floodReports];
      }
      
      // Sort by severity (high > medium > low) then by distance
      _warnings.sort((a, b) {
        const severityOrder = {'high': 0, 'medium': 1, 'low': 2};
        int severityCompare = (severityOrder[a.severity] ?? 999)
            .compareTo(severityOrder[b.severity] ?? 999);
        if (severityCompare != 0) return severityCompare;
        return a.distance.compareTo(b.distance);
      });

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to fetch warnings: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshWarnings() async {
    await fetchWarnings();
  }

  Future<List<Warning>> _fetchWeatherAlerts() async {
    try {
      final response = await http
          .get(Uri.parse('https://api.data.gov.my/weather/warning'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final warnings = <Warning>[];

        // Parse weather alerts from data.gov.my
        if (data is Map && data['metadata'] != null) {
          // Filter for Sarawak warnings
          final alerts = data['data'] ?? [];
          if (alerts is List) {
            for (var alert in alerts) {
              try {
                // Map weather warning types to our severity levels
                final description = alert['description'] ?? 'Weather alert';
                final affectedState = alert['state'] ?? '';

                // Only include Sarawak alerts
                if (!affectedState
                    .toLowerCase()
                    .contains('sarawak')) {
                  continue;
                }

                final severity = _getWeatherAlertSeverity(description);
                final type = _getWeatherAlertType(description);

                warnings.add(Warning(
                  id: 'weather_${alert['id'] ?? DateTime.now().millisecondsSinceEpoch}',
                  type: type,
                  location: affectedState.isEmpty
                      ? 'Sarawak Region'
                      : affectedState,
                  severity: severity,
                  distance: _currentPosition != null
                      ? 5.0
                      : 10.0, // Approx distance; can be refined with geocoding
                  description:
                      description,
                  timestamp: DateTime.parse(alert['dateIssued'] ??
                      DateTime.now().toIso8601String()),
                  latitude: 2.1234, // Sarawak center
                  longitude: 112.5678,
                ));
              } catch (e) {
                debugPrint('Error parsing weather alert: $e');
                continue;
              }
            }
          }
        }
        return warnings;
      } else {
        debugPrint(
            'Weather API error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching weather alerts: $e');
      return [];
    }
  }

  Future<List<Warning>> _fetchFloodReports() async {
    try {
      final response = await http
          .get(Uri.parse(
              'https://banjir-api.herokuapp.com/api/v1/reports.json?negeri=sarawak'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final warnings = <Warning>[];

        // Parse flood reports from banjir-api
        if (data is Map && data['data'] is List) {
          for (var report in data['data']) {
            try {
              final severity = _getFloodSeverity(report['level'] ?? 'Normal');
              final location = report['nama_lokasi'] ??
                  report['lokasi'] ??
                  'Sarawak Location';
              final coords = report['coords'];

              double lat = 2.1234;
              double lng = 112.5678;

              // Try to parse coordinates if available
              if (coords is Map) {
                if (coords['lat'] != null) lat = (coords['lat'] as num).toDouble();
                if (coords['lng'] != null) lng = (coords['lng'] as num).toDouble();
              }

              // Calculate distance if we have current position
              double distance = 5.0;
              if (_currentPosition != null) {
                distance = _calculateDistance(
                  _currentPosition!.latitude,
                  _currentPosition!.longitude,
                  lat,
                  lng,
                );
              }

              warnings.add(Warning(
                id: 'flood_${report['id'] ?? report['lokasi'] ?? DateTime.now().millisecondsSinceEpoch}',
                type: 'Flood',
                location: location,
                severity: severity,
                distance: distance,
                description:
                    'Water level: ${report['level'] ?? 'Unknown'}. Status: ${report['status'] ?? 'Monitoring'}',
                timestamp: DateTime.tryParse(
                        report['timestamp'] ?? '') ??
                    DateTime.now(),
                latitude: lat,
                longitude: lng,
              ));
            } catch (e) {
              debugPrint('Error parsing flood report: $e');
              continue;
            }
          }
        }
        return warnings;
      } else {
        debugPrint('Flood API error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching flood reports: $e');
      return [];
    }
  }

  String _getWeatherAlertType(String description) {
    final desc = description.toLowerCase();
    if (desc.contains('heavy rain') || desc.contains('hujan lebat')) {
      return 'Heavy Rain';
    } else if (desc.contains('thunderstorm') || desc.contains('ribut')) {
      return 'Thunderstorm';
    } else if (desc.contains('landslide') || desc.contains('longsoran')) {
      return 'Landslide';
    } else if (desc.contains('flood') || desc.contains('banjir')) {
      return 'Flood';
    }
    return 'Weather Alert';
  }

  String _getWeatherAlertSeverity(String description) {
    final desc = description.toLowerCase();
    if (desc.contains('extreme') ||
        desc.contains('ekstrim') ||
        desc.contains('danger')) {
      return 'high';
    } else if (desc.contains('warning') || desc.contains('amaran')) {
      return 'medium';
    }
    return 'low';
  }

  String _getFloodSeverity(String level) {
    switch (level.toLowerCase()) {
      case 'danger':
      case 'bahaya':
        return 'high';
      case 'warning':
      case 'amaran':
        return 'medium';
      case 'alert':
      case 'alert zone':
      case 'zon amaran':
        return 'low';
      default:
        return 'low';
    }
  }

  // Haversine formula to calculate distance between two coordinates
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295;
    final a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) *
            cos(lat2 * p) *
            (1 - cos((lon2 - lon1) * p)) /
            2;
    return 12742 * asin(sqrt(a));
  }

  List<Warning> getWarningsBySeverity(String severity) {
    return _warnings.where((w) => w.severity == severity).toList();
  }

  List<Warning> getNearbyWarnings({double radiusKm = 5.0}) {
    return _warnings.where((w) => w.distance <= radiusKm).toList();
  }

  // Toggle demo mode and refresh warnings
  void toggleDemoMode() {
    useDemo = !useDemo;
    fetchWarnings();
  }

  List<Warning> _generateDemoWarnings() {
    // Demo warnings with realistic Sarawak locations around Lubok Antu
    final now = DateTime.now();
    return [
      Warning(
        id: 'demo_1',
        type: 'Flood',
        location: 'Sungai Besar (Main River)',
        severity: 'high',
        distance: 0.8,
        description: 'Water level: DANGER. Do not approach. Risk of flash floods.',
        timestamp: now.subtract(Duration(minutes: 15)),
        latitude: 2.1150,
        longitude: 112.5750,
      ),
      Warning(
        id: 'demo_2',
        type: 'Heavy Rain',
        location: 'Lubok Antu Town Center',
        severity: 'high',
        distance: 0.3,
        description: 'Heavy rainfall expected. Stay indoors if possible.',
        timestamp: now.subtract(Duration(minutes: 5)),
        latitude: 2.1234,
        longitude: 112.5678,
      ),
      Warning(
        id: 'demo_3',
        type: 'Landslide',
        location: 'Bukit Tinggi Road (KM 15)',
        severity: 'medium',
        distance: 4.2,
        description: 'Minor landslide detected. Road partially blocked. Use bypass.',
        timestamp: now.subtract(Duration(hours: 2)),
        latitude: 2.0856,
        longitude: 112.6234,
      ),
      Warning(
        id: 'demo_4',
        type: 'Road Closure',
        location: 'Jalan Pasar (Market Street)',
        severity: 'low',
        distance: 1.1,
        description: 'Temporary closure for road maintenance. Expected duration: 3 hours.',
        timestamp: now.subtract(Duration(hours: 1)),
        latitude: 2.1320,
        longitude: 112.5550,
      ),
      Warning(
        id: 'demo_5',
        type: 'Flood',
        location: 'Sepalit Junction',
        severity: 'medium',
        distance: 5.8,
        description: 'Water level: WARNING. Monitor situation closely.',
        timestamp: now.subtract(Duration(hours: 3)),
        latitude: 2.0678,
        longitude: 112.5890,
      ),
    ];
  }
}
