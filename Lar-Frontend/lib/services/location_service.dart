import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Request location permission from user
  static Future<bool> requestLocationPermission() async {
    try {
      final status = await Geolocator.checkPermission();
      
      if (status == LocationPermission.denied) {
        final result = await Geolocator.requestPermission();
        print('📍 Location permission requested: $result');
        return result == LocationPermission.whileInUse ||
               result == LocationPermission.always;
      } else if (status == LocationPermission.deniedForever) {
        print('❌ Location permission permanently denied');
        return false;
      }
      
      print('✅ Location permission already granted');
      return true;
    } catch (e) {
      print('⚠️ Error requesting location permission: $e');
      return false;
    }
  }

  /// Get current user location
  static Future<Position?> getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return position;
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  /// Check if location services are enabled
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Check current location permission status
  static Future<LocationPermission> checkPermissionStatus() async {
    return await Geolocator.checkPermission();
  }
}
