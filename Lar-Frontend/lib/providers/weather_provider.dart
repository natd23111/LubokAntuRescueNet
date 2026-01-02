import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class WeatherData {
  final String description;
  final double temperature;
  final int weatherCode;
  final double windSpeed;

  WeatherData({
    required this.description,
    required this.temperature,
    required this.weatherCode,
    required this.windSpeed,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final current = json['current'];
    return WeatherData(
      description: _getWeatherDescription(current['weather_code']),
      temperature: (current['temperature_2m'] as num).toDouble(),
      weatherCode: current['weather_code'] ?? 0,
      windSpeed: (current['wind_speed_10m'] as num).toDouble(),
    );
  }

  static String _getWeatherDescription(int code) {
    // WMO Weather interpretation codes
    switch (code) {
      case 0: return 'Clear sky';
      case 1: case 2: return 'Partly cloudy';
      case 3: return 'Overcast';
      case 45: case 48: return 'Foggy';
      case 51: case 53: case 55: return 'Light drizzle';
      case 61: case 63: case 65: return 'Rain';
      case 71: case 73: case 75: return 'Snow';
      case 77: return 'Snow grains';
      case 80: case 81: case 82: return 'Rain showers';
      case 85: case 86: return 'Snow showers';
      case 95: case 96: case 99: return 'Thunderstorm';
      default: return 'Unknown';
    }
  }

  // Get main weather category
  String get main {
    if (weatherCode == 0) return 'Clear';
    if (weatherCode <= 3) return 'Clouds';
    if (weatherCode == 45 || weatherCode == 48) return 'Mist';
    if (weatherCode >= 51 && weatherCode <= 67) return 'Rain';
    if (weatherCode >= 71 && weatherCode <= 77) return 'Snow';
    if (weatherCode >= 80 && weatherCode <= 82) return 'Rain';
    if (weatherCode >= 85 && weatherCode <= 86) return 'Snow';
    if (weatherCode >= 95 && weatherCode <= 99) return 'Thunderstorm';
    return 'Unknown';
  }
}

class WeatherProvider extends ChangeNotifier {
  static const String _apiUrl = 'https://api.open-meteo.com/v1/forecast';

  WeatherData? _currentWeather;
  bool _isLoading = false;
  String? _error;
  Position? _currentPosition;

  // Getters
  WeatherData? get currentWeather => _currentWeather;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Position? get currentPosition => _currentPosition;

  WeatherProvider() {
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    try {
      final hasPermission = await _checkLocationPermission();
      if (hasPermission) {
        await _getCurrentLocation();
        await fetchWeather();
      }
    } catch (e) {
      _error = 'Failed to initialize location: $e';
      notifyListeners();
    }
  }

  Future<bool> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    
    if (permission == LocationPermission.denied) {
      _error = 'Location permission denied';
      notifyListeners();
      return false;
    }
    
    if (permission == LocationPermission.deniedForever) {
      _error = 'Location permission permanently denied. Please enable in settings.';
      notifyListeners();
      return false;
    }
    
    return permission == LocationPermission.whileInUse || 
           permission == LocationPermission.always;
  }

  Future<void> _getCurrentLocation() async {
    try {
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      notifyListeners();
    } catch (e) {
      _error = 'Failed to get location: $e';
      notifyListeners();
    }
  }

  Future<void> fetchWeather() async {
    if (_currentPosition == null) {
      _error = 'Location not available';
      notifyListeners();
      return;
    }

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final url = Uri.parse(
        '$_apiUrl?latitude=${_currentPosition!.latitude}&longitude=${_currentPosition!.longitude}&current=temperature_2m,weather_code,wind_speed_10m&timezone=auto'
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        _currentWeather = WeatherData.fromJson(jsonData);
        _isLoading = false;
        notifyListeners();
      } else {
        _isLoading = false;
        _error = 'Failed to fetch weather: ${response.statusCode}';
        notifyListeners();
      }
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to fetch weather: $e';
      notifyListeners();
    }
  }

  Future<void> refreshWeather() async {
    await _getCurrentLocation();
    await fetchWeather();
  }

  // Helper method to determine if weather alert should be shown
  bool shouldShowAlert() {
    if (_currentWeather == null) return false;
    
    final main = _currentWeather!.main.toLowerCase();
    final description = _currentWeather!.description.toLowerCase();
    
    // Check for severe weather conditions
    return main.contains('rain') ||
           main.contains('thunderstorm') ||
           main.contains('snow') ||
           description.contains('heavy') ||
           description.contains('storm');
  }

  // Helper method to get alert message
  String getAlertMessage() {
    if (_currentWeather == null) {
      return 'Unable to fetch weather data';
    }
    
    final temp = _currentWeather!.temperature.toStringAsFixed(1);
    final description = _currentWeather!.description;
    // Capitalize each word
    final capitalizedDescription = description
        .split(' ')
        .map((word) => word.replaceFirst(word[0], word[0].toUpperCase()))
        .join(' ');
    return '$capitalizedDescription. Current temperature: ${temp}°C';
  }

  // Helper method to get weather icon
  IconData getWeatherIcon() {
    if (_currentWeather == null) return Icons.cloud_off;
    
    final main = _currentWeather!.main.toLowerCase();
    
    switch (main) {
      case 'clear':
        return Icons.wb_sunny;
      case 'clouds':
        return Icons.cloud;
      case 'rain':
        return Icons.cloud_queue;
      case 'drizzle':
        return Icons.grain;
      case 'thunderstorm':
        return Icons.flash_on;
      case 'snow':
        return Icons.ac_unit;
      case 'mist':
      case 'smoke':
      case 'haze':
      case 'dust':
      case 'fog':
      case 'sand':
      case 'ash':
      case 'squall':
      case 'tornado':
        return Icons.cloud_off;
      default:
        return Icons.cloud;
    }
  }
}
