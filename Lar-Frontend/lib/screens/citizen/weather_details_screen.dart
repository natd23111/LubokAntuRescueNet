import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/weather_provider.dart';

class WeatherDetailsScreen extends StatefulWidget {
  const WeatherDetailsScreen({super.key});

  @override
  _WeatherDetailsScreenState createState() => _WeatherDetailsScreenState();
}

class _WeatherDetailsScreenState extends State<WeatherDetailsScreen> {
  @override
  void initState() {
    super.initState();
    // Optionally refresh weather when screen opens
    Future.microtask(() {
      final weatherProvider = Provider.of<WeatherProvider>(
        context,
        listen: false,
      );
      weatherProvider.refreshWeather();
    });
  }

  String _getWeatherEmoji(String description, String main) {
    final desc = description.toLowerCase();
    final mainLower = main.toLowerCase();

    // Thunderstorm
    if (desc.contains('thunderstorm') || mainLower.contains('thunderstorm')) {
      return '⛈️';
    }

    // Rain
    if (desc.contains('rain') || mainLower.contains('rain')) {
      if (desc.contains('heavy') || desc.contains('shower')) {
        return '🌧️';
      }
      return '🌦️';
    }

    // Snow
    if (desc.contains('snow') || mainLower.contains('snow')) {
      return '❄️';
    }

    // Clear
    if (desc.contains('clear') || mainLower.contains('clear')) {
      return '☀️';
    }

    // Partly cloudy
    if (desc.contains('partly cloudy') || desc.contains('scattered clouds')) {
      return '⛅';
    }

    // Mostly cloudy
    if (desc.contains('overcast') || desc.contains('mostly cloudy')) {
      return '🌥️';
    }

    // Clouds
    if (desc.contains('cloud') || mainLower.contains('cloud')) {
      return '☁️';
    }

    // Mist/Fog
    if (desc.contains('mist') ||
        desc.contains('fog') ||
        mainLower.contains('mist')) {
      return '🌫️';
    }

    // Default
    return '🌤️';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final primaryGreen = Color(0xFF0E9D63);

    return Scaffold(
      backgroundColor: Color(0xFFF6F7F9),
      appBar: AppBar(
        backgroundColor: primaryGreen,
        elevation: 0,
        title: Text(
          l10n.weatherDetails,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<WeatherProvider>(
        builder: (context, weatherProvider, _) {
          if (weatherProvider.isLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: primaryGreen),
                  SizedBox(height: 16),
                  Text(
                    'Fetching weather data...',
                    style: TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            );
          }

          if (weatherProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red),
                  SizedBox(height: 16),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      weatherProvider.error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.red, fontSize: 16),
                    ),
                  ),
                  SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => weatherProvider.refreshWeather(),
                    icon: Icon(Icons.refresh),
                    label: Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                    ),
                  ),
                ],
              ),
            );
          }

          if (weatherProvider.currentWeather == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_off, size: 48, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No weather data available',
                    style: TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            );
          }

          final weather = weatherProvider.currentWeather!;
          final shouldShowAlert = weatherProvider.shouldShowAlert();

          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main weather card
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryGreen.withOpacity(0.8), primaryGreen],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 8),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Current Weather',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                '${weather.temperature.toStringAsFixed(1)}°C',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            _getWeatherEmoji(weather.description, weather.main),
                            style: TextStyle(fontSize: 80),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Text(
                        weather.description
                            .split(' ')
                            .map(
                              (word) => word.replaceFirst(
                                word[0],
                                word[0].toUpperCase(),
                              ),
                            )
                            .join(' '),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24),

                // Weather details grid
                Text(
                  'Weather Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),

                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.2,
                  children: [
                    _buildDetailCard(
                      icon: Icons.wind_power,
                      label: 'Wind Speed',
                      value: '${weather.windSpeed.toStringAsFixed(1)} m/s',
                      bgColor: Colors.blue,
                    ),
                    _buildDetailCard(
                      icon: Icons.cloud,
                      label: 'Condition',
                      value: weather.main,
                      bgColor: Colors.cyan,
                    ),
                    _buildDetailCard(
                      icon: Icons.thermostat,
                      label: 'Feels Like',
                      value: 'Check app',
                      bgColor: Colors.orange,
                    ),
                    _buildDetailCard(
                      icon: Icons.location_on,
                      label: 'Location',
                      value:
                          '${weatherProvider.currentPosition?.latitude.toStringAsFixed(2) ?? 'N/A'},${weatherProvider.currentPosition?.longitude.toStringAsFixed(2) ?? 'N/A'}',
                      bgColor: Colors.purple,
                    ),
                  ],
                ),

                SizedBox(height: 24),

                // Alert status
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: shouldShowAlert
                        ? Colors.orange.shade50
                        : Colors.green.shade50,
                    border: Border.all(
                      color: shouldShowAlert
                          ? Colors.orange.shade300
                          : Colors.green.shade300,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        shouldShowAlert
                            ? Icons.warning_amber_rounded
                            : Icons.check_circle,
                        color: shouldShowAlert ? Colors.orange : Colors.green,
                        size: 32,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              shouldShowAlert
                                  ? 'Weather Alert Active'
                                  : 'Weather Conditions Normal',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: shouldShowAlert
                                    ? Colors.orange.shade900
                                    : Colors.green.shade900,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              shouldShowAlert
                                  ? 'Severe weather detected in your area. Stay cautious.'
                                  : 'Current weather is safe for outdoor activities.',
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24),

                // Refresh button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => weatherProvider.refreshWeather(),
                    icon: Icon(Icons.refresh, color: Colors.white),
                    label: Text(
                      'Refresh Weather',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 12),

                // Last updated
                Center(
                  child: Text(
                    'Last updated: ${DateTime.now().toString().split('.')[0]}',
                    style: TextStyle(color: Colors.black45, fontSize: 12),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailCard({
    required IconData icon,
    required String label,
    required String value,
    required Color bgColor,
  }) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.1),
        border: Border.all(color: bgColor.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: bgColor, size: 28),
          SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54, fontSize: 12),
          ),
          SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: bgColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
