import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:free_map/free_map.dart';
import 'dart:async';
import '../../providers/warnings_provider.dart';
import '../../models/warning.dart';

// MapTiler API key
final String _mapTilerUrl =
    'https://api.maptiler.com/maps/base-v4/{z}/{x}/{y}.png?key=05qm5umVozsJ1MUwgXPY';

class MapWarningsScreen extends StatefulWidget {
  @override
  _MapWarningsScreenState createState() => _MapWarningsScreenState();
}

class _MapWarningsScreenState extends State<MapWarningsScreen> {
  late final MapController _mapController;
  late StreamSubscription _mapSub;
  double _currentZoom = 13.0;
  bool _mapReady = false;
  static const LatLng _lubokAntu = LatLng(2.1234, 112.5678);

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    
    // Listen to map events safely - after map renders
    _mapSub = _mapController.mapEventStream.listen((event) {
      try {
        setState(() {
          _currentZoom = event.camera.zoom;
          _mapReady = true;
        });
      } catch (e) {
        // Event doesn't have camera info, skip
      }
    });
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final warningsProvider = Provider.of<WarningsProvider>(context, listen: false);
        warningsProvider.fetchWarnings().then((_) {
          // After fetching warnings, center map on user's current location
          if (mounted && warningsProvider.currentPosition != null) {
            _mapController.move(
              LatLng(
                warningsProvider.currentPosition!.latitude,
                warningsProvider.currentPosition!.longitude,
              ),
              13.0,
            );
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _mapSub.cancel();
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

  // Calculate marker size based on zoom level - aggressive scaling
  double _getMarkerSize(double zoomLevel) {
    if (zoomLevel >= 15) {
      return 100; // Very large when extremely zoomed in
    } else if (zoomLevel >= 14) {
      return 85; // Large icons when zoomed in
    } else if (zoomLevel >= 13) {
      return 70;
    } else if (zoomLevel >= 12) {
      return 55; // Medium icons at normal zoom
    } else if (zoomLevel >= 11) {
      return 40;
    } else if (zoomLevel >= 10) {
      return 28; // Small icons when zoomed out
    } else if (zoomLevel >= 9) {
      return 18;
    } else if (zoomLevel >= 8) {
      return 12;
    } else {
      return 6; // Tiny icons when very far out
    }
  }

  // Calculate emoji size based on zoom level
  double _getEmojiSize(double zoomLevel) {
    if (zoomLevel >= 14) {
      return 28;
    } else if (zoomLevel >= 12) {
      return 18;
    } else if (zoomLevel >= 10) {
      return 10;
    } else if (zoomLevel >= 8) {
      return 6;
    } else {
      return 4;
    }
  }

  Widget _getWarningEmoji(String severity, {double? size}) {
    final iconSize = size ?? 24.0;
    switch (severity.toLowerCase()) {
      case 'high':
        return Icon(Icons.warning_amber_rounded, color: Colors.red, size: iconSize);
      case 'medium':
        return Icon(Icons.warning_amber_rounded, color: Colors.orange, size: iconSize);
      case 'low':
        return Icon(Icons.warning_amber_rounded, color: Colors.amber, size: iconSize);
      default:
        return Icon(Icons.warning_amber_rounded, color: Colors.grey, size: iconSize);
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

      // Center map on current location and reset rotation
      if (mounted) {
        _mapController.move(
          LatLng(position.latitude, position.longitude),
          13.0,
        );
        _mapController.rotate(0); // Reset rotation to face north
        _showError('Centered on your location');
      }
    } catch (e) {
      _showError('Error locating: $e');
      print('Location error: $e');
    }
  }

  void _showWarningDetails(Warning warning, Color primaryGreen) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final severityColor = _getSeverityColor(warning.severity);
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _getWarningEmoji(warning.severity, size: 32),
                      SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(warning.type,
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87)),
                          Text(warning.severity.toUpperCase(),
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: severityColor)),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Divider(),
              SizedBox(height: 12),
              Text('Location',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54)),
              Text(warning.location,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87)),
              SizedBox(height: 16),
              Text('Description',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54)),
              Text(warning.description,
                  style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87)),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: Colors.black54),
                      SizedBox(width: 6),
                      Text(warning.getDistanceText(),
                          style: TextStyle(color: Colors.black54, fontSize: 13)),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 16, color: Colors.black54),
                      SizedBox(width: 6),
                      Text(warning.getTimeAgo(),
                          style: TextStyle(color: Colors.black54, fontSize: 13)),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text('Close',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
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
            title: Text('Map Warnings', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
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
                          initialCenter: warningsProvider.currentPosition != null
                              ? LatLng(
                                  warningsProvider.currentPosition!.latitude,
                                  warningsProvider.currentPosition!.longitude,
                                )
                              : _lubokAntu,
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
                                point: warningsProvider.currentPosition != null
                                    ? LatLng(
                                        warningsProvider.currentPosition!.latitude,
                                        warningsProvider.currentPosition!.longitude,
                                      )
                                    : _lubokAntu,
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
                                final zoom = _mapReady ? _currentZoom : 13.0;
                                final markerSize = _getMarkerSize(zoom);
                                final emojiSize = _getEmojiSize(zoom);
                                return Marker(
                              point: LatLng(warning.latitude, warning.longitude),
                              width: markerSize,
                              height: markerSize * 0.75, // Slim down the height
                              alignment: Alignment.topCenter,
                              child: GestureDetector(
                                onTap: () {
                                  _showWarningDetails(warning, primaryGreen);
                                },
                                child: Tooltip(
                                  message: '${warning.type} - ${warning.location}',
                                  child: Center(
                                    child: BlinkingWarningMarker(
                                      severity: warning.severity,
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
                                          _getWarningEmoji(warning.severity, size: 20),
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
                          icon: Icon(Icons.refresh, color: Colors.white),
                          label: Text('Refresh Map',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                          child: Text('Back',
                              style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w600)),
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
            child: Container(
              margin: EdgeInsets.only(top: 4),
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(6),
              ),
              child: _getWarningEmoji(warning.severity, size: 16),
            ),
          ),
        ),
      );
    }).toList();
  }
}

// Blinking warning marker widget
class BlinkingWarningMarker extends StatefulWidget {
  final String severity;

  const BlinkingWarningMarker({required this.severity});

  @override
  _BlinkingWarningMarkerState createState() => _BlinkingWarningMarkerState();
}

class _BlinkingWarningMarkerState extends State<BlinkingWarningMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);

    _opacityAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
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

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacityAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _getSeverityColor(widget.severity),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        );
      },
    );
  }
}
