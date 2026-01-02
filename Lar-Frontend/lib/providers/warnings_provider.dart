import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'dart:math';
import '../models/warning.dart';

class WarningsProvider extends ChangeNotifier {
  List<Warning> _warnings = [];
  bool _isLoading = false;
  String? _error;
  Position? _currentPosition;

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

      // Fetch from Firebase emergency reports
      _warnings = await _fetchFirebaseWarnings();
      
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
      debugPrint('Warning fetch error: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshWarnings() async {
    await fetchWarnings();
  }

  Future<List<Warning>> _fetchFirebaseWarnings() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final warnings = <Warning>[];

      debugPrint('=== FIREBASE WARNINGS FETCH START ===');
      debugPrint('Demo mode: $useDemo');
      debugPrint('Current location: ${_currentPosition?.latitude}, ${_currentPosition?.longitude}');

      // Query emergency reports from Firestore
      final snapshot = await firestore
          .collection('emergency_reports')
          .orderBy('created_at', descending: true)
          .limit(50)
          .get()
          .timeout(const Duration(seconds: 15));

      debugPrint('[WarningsProvider] Found ${snapshot.docs.length} emergency reports in Firebase');

      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();
          debugPrint('[WarningsProvider] Report ${data['id']}:');
          debugPrint('  Type: ${data['type']}');
          debugPrint('  Title: ${data['title']}');
          debugPrint('  Location: ${data['location']}');
          debugPrint('  Status: ${data['status']}');
          debugPrint('  Priority: ${data['priority']}');
          debugPrint('  Lat: ${data['latitude']}, Lon: ${data['longitude']}');
          
          // Parse emergency report data using correct field names from Firebase schema
          final incidentType = (data['type'] ?? 'Unknown') as String;
          final incidentLocation = (data['location'] ?? 'Unknown Location') as String;
          final description = (data['description'] ?? '') as String;
          final status = (data['status'] ?? 'reported') as String;
          final priority = (data['priority'] ?? 'medium') as String;
          
          // Parse created_at timestamp
          final createdAt = data['created_at'] != null
              ? DateTime.parse(data['created_at'].toString())
              : DateTime.now();

          // Get coordinates from the report (citizen-provided location)
          double latitude = 2.1234; // Default: Lubok Antu center
          double longitude = 112.5678;

          if (data['latitude'] != null && data['longitude'] != null) {
            latitude = (data['latitude'] as num).toDouble();
            longitude = (data['longitude'] as num).toDouble();
          }

          // Calculate distance from current position
          double distance = _calculateDistance(
            _currentPosition?.latitude ?? 2.1234,
            _currentPosition?.longitude ?? 112.5678,
            latitude,
            longitude,
          );

          // Map incident type to warning type and severity
          final warningType = _mapIncidentTypeToWarning(incidentType);
          // Use both incident type AND priority to determine severity
          final severity = _mapIncidentSeverity(incidentType, status, priority);

          debugPrint('[WarningsProvider] Mapped to: type=$warningType, severity=$severity, distance=${distance.toStringAsFixed(2)}km');

          warnings.add(Warning(
            id: doc.id,
            type: warningType,
            location: incidentLocation,
            severity: severity,
            distance: distance,
            description: description.isEmpty
                ? 'Citizen reported: $incidentType'
                : description,
            timestamp: createdAt,
            latitude: latitude,
            longitude: longitude,
          ));
        } catch (e) {
          debugPrint('[WarningsProvider] Error parsing emergency report: $e');
          continue;
        }
      }

      debugPrint('[WarningsProvider] Total warnings extracted: ${warnings.length}');
      debugPrint('[WarningsProvider] Firebase fetch complete\n');
      return warnings;
    } catch (e) {
      debugPrint('[WarningsProvider] Error fetching Firebase warnings: $e');
      return [];
    }
  }

  // Map incident types from emergency reports to warning types
  String _mapIncidentTypeToWarning(String incidentType) {
    if (incidentType.isEmpty || incidentType.toLowerCase() == 'unknown') {
      return 'Emergency Alert';
    }
    
    final type = incidentType.toLowerCase().trim();
    
    // Exact matches first
    if (type == 'flood' || type == 'banjir') {
      return 'Flood';
    } else if (type == 'landslide' || type == 'longsoran') {
      return 'Landslide';
    } else if (type == 'heavy rain' || type == 'hujan lebat') {
      return 'Heavy Rain';
    } else if (type == 'road closure' || type == 'penutupan jalan') {
      return 'Road Closure';
    } else if (type == 'bridge closure' || type == 'penutupan jambatan') {
      return 'Bridge Closure';
    } else if (type == 'fire' || type == 'kebakaran') {
      return 'Fire';
    } else if (type == 'accident' || type == 'kemalangan') {
      return 'Accident';
    } else if (type == 'thunderstorm' || type == 'ribut') {
      return 'Thunderstorm';
    }
    
    // Substring matches
    if (type.contains('flood') || type.contains('banjir')) {
      return 'Flood';
    } else if (type.contains('landslide') || type.contains('longsoran')) {
      return 'Landslide';
    } else if (type.contains('rain') || type.contains('hujan')) {
      return 'Heavy Rain';
    } else if (type.contains('road') || type.contains('jalan')) {
      return 'Road Closure';
    } else if (type.contains('bridge') || type.contains('jambatan')) {
      return 'Bridge Closure';
    } else if (type.contains('fire') || type.contains('kebakaran')) {
      return 'Fire';
    } else if (type.contains('accident') || type.contains('kemalangan')) {
      return 'Accident';
    } else if (type.contains('storm') || type.contains('ribut')) {
      return 'Thunderstorm';
    }
    
    // Return original if no match found
    return incidentType;
  }

  // Map incident severity based on type, status, and priority from Firebase
  // Available types: Flood, Fire, Accident, Medical Emergency, Landslide, Other
  String _mapIncidentSeverity(String incidentType, String status, String priority) {
    if (incidentType.isEmpty) {
      return 'medium';
    }
    
    final type = incidentType.toLowerCase().trim();
    final pri = priority.toLowerCase().trim();

    // HIGH SEVERITY - Life-threatening incidents
    // Flood, Fire, Landslide, Medical Emergency
    if (type.contains('flood') || type.contains('banjir') ||
        type.contains('fire') || type.contains('kebakaran') || 
        type.contains('landslide') || type.contains('longsoran') ||
        type.contains('medical') || type.contains('emergency')) {
      return 'high';
    }

    // MEDIUM SEVERITY - Accidents
    if (type.contains('accident') || type.contains('kemalangan')) {
      // Priority can upgrade accident to high if explicitly marked
      if (pri == 'high' || pri == 'urgent') {
        return 'high';
      }
      return 'medium';
    }

    // LOW SEVERITY - Other/Unknown incidents
    if (type.contains('other') || type.contains('lain')) {
      // Priority cannot upgrade 'Other' to high - keep it low
      return 'low';
    }

    // Default to medium
    return 'medium';
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


}
