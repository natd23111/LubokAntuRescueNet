import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:free_map/free_map.dart';
import 'dart:async';
import '../../providers/warnings_provider.dart';

// MapTiler API key
final String _mapTilerUrl =
    'https://api.maptiler.com/maps/base-v4/{z}/{x}/{y}.png?key=05qm5umVozsJ1MUwgXPY';

class MapWarningsScreen extends StatefulWidget {
  @override
  _MapWarningsScreenState createState() => _MapWarningsScreenState();
}

class _MapWarningsScreenState extends State<MapWarningsScreen> {
  late final MapController _mapController;
  static const LatLng _lubokAntu = LatLng(2.1234, 112.5678);

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final warningsProvider = Provider.of<WarningsProvider>(context, listen: false);
        warningsProvider.fetchWarnings();
      }
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  String _getWarningEmoji(String type) {
    switch (type.toLowerCase()) {
      case 'flood':
        return '🌊';
      case 'landslide':
        return '⛏️';
      case 'road closure':
        return '🚫';
      case 'heavy rain':
        return '🌧️';
      case 'bridge closure':
        return '🌉';
      default:
        return '⚠️';
    }
  }

  Future<void> _openInteractiveMap() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showError('Location services are disabled. Please enable them.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        _showError('Location permission was denied.');
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        _showError('Location permissions are permanently denied. Open app settings to enable.');
        return;
      }

      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('Location request timed out'),
      );

      // Center map on current location
      if (mounted) {
        _mapController.move(
          LatLng(position.latitude, position.longitude),
          13.0,
        );
      }
    } catch (e) {
      _showError('Error: $e');
      print('Map error: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _zoomIn() {
    _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1);
  }

  void _zoomOut() {
    _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1);
  }

  Future<void> _locateCurrentPosition() async {
    try {
      _showError('Locating you...');
      
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showError('Location services are disabled. Please enable them.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        _showError('Location permission was denied.');
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        _showError('Location permissions are permanently denied. Open app settings to enable.');
        return;
      }

      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('Location request timed out'),
      );

      // Center map on current location
      if (mounted) {
        _mapController.move(
          LatLng(position.latitude, position.longitude),
          15.0,
        );
        _showError('You are located at ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}');
      }
    } catch (e) {
      _showError('Error locating: $e');
      print('Location error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryGreen = Color(0xFF0E9D63);

    return Consumer<WarningsProvider>(
      builder: (context, warningsProvider, _) {
        return Scaffold(
          backgroundColor: Color(0xFFF6F7F9),
          appBar: AppBar(
            backgroundColor: primaryGreen,
            elevation: 0,
            title: Text('Map Warnings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              Padding(
                padding: EdgeInsets.only(right: 16),
                child: Tooltip(
                  message: warningsProvider.useDemo ? 'Switch to Real Data' : 'Switch to Demo Data',
                  child: GestureDetector(
                    onTap: () {
                      warningsProvider.toggleDemoMode();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(warningsProvider.useDemo ? '📍 Demo Mode ON' : '🌐 Real Data Mode ON'),
                          duration: Duration(seconds: 2),
                          backgroundColor: primaryGreen,
                        ),
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: warningsProvider.useDemo ? Colors.yellow.shade700 : Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            warningsProvider.useDemo ? Icons.developer_mode : Icons.language,
                            color: Colors.white,
                            size: 18,
                          ),
                          SizedBox(width: 4),
                          Text(
                            warningsProvider.useDemo ? 'DEMO' : 'LIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
      body: Consumer<WarningsProvider>(
        builder: (context, warningsProvider, _) {
          return SingleChildScrollView(
            child: Column(
              children: [
                // Real Interactive Map with Warning Markers
                Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 350,
                      child: FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _lubokAntu,
                          initialZoom: 13.0,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: _mapTilerUrl,
                            userAgentPackageName: 'dev.fleaflet.flutter_map.example',
                          ),
                          // Your Location Marker
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _lubokAntu,
                                width: 80,
                                height: 80,
                                alignment: Alignment.topCenter,
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      color: primaryGreen,
                                      size: 40,
                                    ),
                                    Text(
                                      'You',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: primaryGreen,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          // Warning Markers
                          if (warningsProvider.warnings.isNotEmpty)
                            MarkerLayer(
                              markers: warningsProvider.warnings.map((warning) {
                                final color = _getSeverityColor(warning.severity);
                                return Marker(
                              point: LatLng(warning.latitude, warning.longitude),
                              width: 80,
                              height: 80,
                              alignment: Alignment.topCenter,
                              child: Tooltip(
                                message: '${warning.type} - ${warning.location}',
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 3),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 6,
                                        spreadRadius: 2,
                                      )
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      _getWarningEmoji(warning.type),
                                      style: TextStyle(fontSize: 28),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                    ),
                    // Map Controls (Zoom buttons) - Positioned inside Stack
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: Column(
                        spacing: 8,
                        children: [
                          _buildMapButton('+', _zoomIn),
                          _buildMapButton('−', _zoomOut),
                        ],
                      ),
                    ),
                  ],
                ),

                // Current Location Banner - Clickable
                GestureDetector(
                  onTap: _locateCurrentPosition,
                  child: Container(
                    color: Colors.white,
                    padding: EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(Icons.my_location, color: primaryGreen, size: 20),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Your Current Location',
                                  style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
                              Text('Tap to locate on map',
                                  style: TextStyle(color: Colors.black54, fontSize: 12)),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward, color: primaryGreen, size: 20),
                      ],
                    ),
                  ),
                ),

                // Warnings List
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Active Warnings Nearby',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text('${warningsProvider.activeWarningsCount}',
                                style: TextStyle(
                                    color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      if (warningsProvider.isLoading)
                        Center(
                          child: CircularProgressIndicator(color: primaryGreen),
                        )
                      else if (warningsProvider.error != null)
                        Center(
                          child: Text(warningsProvider.error!,
                              style: TextStyle(color: Colors.red),
                              textAlign: TextAlign.center),
                        )
                      else if (warningsProvider.warnings.isEmpty)
                        Center(
                          child: Column(
                            children: [
                              Icon(Icons.check_circle, size: 48, color: Colors.green),
                              SizedBox(height: 16),
                              Text('No warnings in your area',
                                  style: TextStyle(color: Colors.black54)),
                            ],
                          ),
                        )
                      else
                        Column(
                          spacing: 12,
                          children: warningsProvider.warnings.map((warning) {
                            final severityColor = _getSeverityColor(warning.severity);
                            return Container(
                              padding: EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: severityColor.withOpacity(0.1),
                                border: Border.all(color: severityColor.withOpacity(0.5), width: 2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Text(_getWarningEmoji(warning.type), style: TextStyle(fontSize: 20)),
                                          SizedBox(width: 10),
                                          Text(warning.type,
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black87)),
                                        ],
                                      ),
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.7),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(warning.severity.toUpperCase(),
                                            style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: severityColor)),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 10),
                                  Text(warning.location,
                                      style: TextStyle(
                                          color: Colors.black87, fontWeight: FontWeight.w500)),
                                  SizedBox(height: 6),
                                  Text(warning.description,
                                      style: TextStyle(color: Colors.black54, fontSize: 13)),
                                  SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.location_on, size: 14, color: Colors.black54),
                                          SizedBox(width: 4),
                                          Text(warning.getDistanceText(),
                                              style: TextStyle(color: Colors.black54, fontSize: 12)),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Icon(Icons.schedule, size: 14, color: Colors.black54),
                                          SizedBox(width: 4),
                                          Text(warning.getTimeAgo(),
                                              style: TextStyle(color: Colors.black54, fontSize: 12)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),

                // Legend
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 16),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Warning Levels',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                      SizedBox(height: 12),
                      _buildLegendItem(Colors.red, 'High - Immediate danger'),
                      SizedBox(height: 10),
                      _buildLegendItem(Colors.orange, 'Medium - Exercise caution'),
                      SizedBox(height: 10),
                      _buildLegendItem(Colors.amber, 'Low - Be aware'),
                    ],
                  ),
                ),

                SizedBox(height: 16),

                // Buttons
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    spacing: 10,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () => warningsProvider.refreshWarnings(),
                          icon: Icon(Icons.refresh),
                          label: Text('Refresh Map'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryGreen,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Back'),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
      },
    );
  }

  Widget _buildMapButton(String label, VoidCallback onPressed) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          child: Center(
            child: Text(label, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 12),
        Text(label, style: TextStyle(color: Colors.black87, fontSize: 13)),
      ],
    );
  }

  List<Widget> _buildWarningMarkers(WarningsProvider warningsProvider) {
    return warningsProvider.warnings.map((warning) {
      final color = _getSeverityColor(warning.severity);
      // Simple positioning - in a real app, you'd use actual map coordinates
      final positions = [
        {'top': 80.0, 'left': 60.0},
        {'top': 160.0, 'right': 80.0},
        {'bottom': 80.0, 'left': 100.0},
        {'top': 120.0, 'right': 120.0},
        {'bottom': 120.0, 'right': 60.0},
      ];

      final position = positions[warningsProvider.warnings.indexOf(warning) % positions.length];

      return Positioned(
        top: position['top'] as double?,
        left: position['left'] as double?,
        right: position['right'] as double?,
        bottom: position['bottom'] as double?,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, spreadRadius: 2)],
          ),
          child: Center(
            child: Text(
              _getWarningEmoji(warning.type),
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      );
    }).toList();
  }
}
