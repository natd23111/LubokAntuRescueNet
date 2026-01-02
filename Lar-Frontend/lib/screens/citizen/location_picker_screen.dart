import 'package:flutter/material.dart';
import 'package:free_map/free_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:async';

// Model for address components
class AddressComponents {
  final String street;
  final String postalCode;
  final String locality;
  final String administrativeArea;
  final String fullAddress;

  AddressComponents({
    required this.street,
    required this.postalCode,
    required this.locality,
    required this.administrativeArea,
    required this.fullAddress,
  });
}

// MapTiler API key
final String _mapTilerUrl =
    'https://api.maptiler.com/maps/base-v4/{z}/{x}/{y}.png?key=05qm5umVozsJ1MUwgXPY';

class LocationPickerScreen extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;

  const LocationPickerScreen({
    Key? key,
    this.initialLatitude,
    this.initialLongitude,
  }) : super(key: key);

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  late final MapController _mapController;
  LatLng? selectedLocation;
  String selectedAddress = '';
  AddressComponents? addressComponents;
  bool isLoading = true;
  bool isLoadingAddress = false;
  double? gpsAccuracy;
  String locationStatus = 'Acquiring location...'; // "GPS verified", "approximate", "Manual"
  Timer? _searchDebounceTimer;
  Map<String, AddressComponents> _placemarkCache = {}; // Cache for placemark results
  List<LatLng> _locationHistory = []; // Recent locations for quick access
  bool _isDraggingMarker = false;
  double _zoomLevel = 15.0;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeLocation();
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    _searchDebounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    try {
      // If initial location provided, use it
      if (widget.initialLatitude != null && widget.initialLongitude != null) {
        final location =
            LatLng(widget.initialLatitude!, widget.initialLongitude!);
        await _setLocation(location);
      } else {
        // Otherwise, get current location
        await _getCurrentLocation();
      }
    } catch (e) {
      print('Error initializing location: $e');
      if (mounted) {
        _showSnackBar('Error: $e');
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      print('Attempting to get current location...');
      
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services are disabled');
        _showError('Location services are disabled. Please enable them in settings.');
        return; // Don't set any location, just return
      }

      LocationPermission permission = await Geolocator.checkPermission();
      print('Location permission status: $permission');
      
      if (permission == LocationPermission.denied) {
        print('Requesting location permission...');
        permission = await Geolocator.requestPermission();
        print('Permission requested result: $permission');
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        print('Location permission denied or permanently denied');
        _showError('Location permission denied. Please grant permission in app settings.');
        return; // Don't set any location, just return
      }

      print('Getting current position with best accuracy...');
      
      // Try to get GPS first (high accuracy), then fallback to network
      Position position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
          timeLimit: const Duration(seconds: 10),
        );
      } catch (e) {
        print('GPS acquisition timed out, trying with lower accuracy...');
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.reduced,
        );
      }

      print('Current position obtained: ${position.latitude}, ${position.longitude}, accuracy: ${position.accuracy}m');
      
      final location = LatLng(position.latitude, position.longitude);
      
      // Validate location is within Sarawak bounds (rough bounds)
      if (!_isValidLocation(location)) {
        print('Location appears to be outside valid area');
        _showError('Location appears to be outside service area');
        return; // Don't set any location if outside bounds
      }

      // Store in history
      _locationHistory.insert(0, location);
      if (_locationHistory.length > 10) {
        _locationHistory.removeLast(); // Keep only 10 recent
      }

      String status = 'GPS verified';
      if (position.accuracy > 50) {
        status = 'approximate'; // Low accuracy GPS
      }
      
      await _setLocation(location, status, position.accuracy);
    } catch (e) {
      print('Error getting current location: $e');
      _showError('Could not acquire your location.');
      // Don't set any fallback location - let user see the map is waiting
    }
  }

  bool _isValidLocation(LatLng location) {
    // Rough bounds for Sarawak, Malaysia
    // Latitude: ~0.85 to ~5
    // Longitude: ~109.6 to ~115.5
    const double minLat = 0.85;
    const double maxLat = 5.5;
    const double minLon = 109.0;
    const double maxLon = 116.0;

    return location.latitude >= minLat &&
        location.latitude <= maxLat &&
        location.longitude >= minLon &&
        location.longitude <= maxLon;
  }

  Future<void> _setLocation(LatLng location, [String status = 'Manual', double? accuracy]) async {
    try {
      print('Setting location: ${location.latitude}, ${location.longitude}');
      
      // Move map immediately to location (don't wait for geocoding)
      if (mounted) {
        setState(() {
          selectedLocation = location;
          isLoading = false; // Show map immediately
          isLoadingAddress = true; // Load address in background
          locationStatus = status;
          gpsAccuracy = accuracy;
        });

        print('Moving map to: ${location.latitude}, ${location.longitude}');
        // Move camera to location immediately
        _mapController.move(location, _zoomLevel);
      }

      // Fetch address in background while map is moving
      String address = '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}';
      AddressComponents? components;
      
      try {
        String cacheKey = '${location.latitude},${location.longitude}';
        
        // Check cache first
        if (_placemarkCache.containsKey(cacheKey)) {
          components = _placemarkCache[cacheKey];
          address = components!.fullAddress;
        } else {
          // Try to get the full address from reverse geocoding with shorter timeout
          final List<Placemark> placemarks = await placemarkFromCoordinates(
            location.latitude,
            location.longitude,
          ).timeout(const Duration(seconds: 5));

          if (placemarks.isNotEmpty) {
            final Placemark place = placemarks[0];
            // Build complete address with all available fields, prioritizing street number first
            String street = place.street ?? '';
            String thoroughfare = place.thoroughfare ?? '';
            String postalCode = place.postalCode ?? '';
            String locality = place.locality ?? '';
            String administrativeArea = place.administrativeArea ?? '';

            List<String> addressParts = [];
            if (street.isNotEmpty) addressParts.add(street);
            if (thoroughfare.isNotEmpty && thoroughfare != street) addressParts.add(thoroughfare);
            if (postalCode.isNotEmpty) addressParts.add(postalCode);
            if (locality.isNotEmpty) addressParts.add(locality);
            if (administrativeArea.isNotEmpty) addressParts.add(administrativeArea);
            
            address = addressParts.join(', ');
            if (address.isEmpty) {
              address = '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}';
            }

            // Cache the result
            components = AddressComponents(
              street: street,
              postalCode: postalCode,
              locality: locality,
              administrativeArea: administrativeArea,
              fullAddress: address,
            );
            _placemarkCache[cacheKey] = components;
          }
        }
      } catch (e) {
        print('Geocoding error (non-blocking): $e');
        // Continue with coordinate address if geocoding fails
      }

      if (mounted) {
        setState(() {
          selectedAddress = address;
          addressComponents = components;
          isLoadingAddress = false;
        });
      }
    } catch (e) {
      print('Error setting location: $e');
      if (mounted) {
        setState(() {
          selectedLocation = LatLng(2.8127, 112.3277);
          selectedAddress =
              '${selectedLocation!.latitude.toStringAsFixed(4)}, ${selectedLocation!.longitude.toStringAsFixed(4)}';
          isLoadingAddress = false;
          locationStatus = 'Manual';
        });
      }
    }
  }

  void _onMapTap(LatLng location) async {
    setState(() => _isDraggingMarker = false);
    await _setLocation(location, 'Manual');
    _showSnackBar('Location updated');
  }

  void _zoomIn() {
    if (_zoomLevel < 18) {
      _zoomLevel += 1.0;
      if (selectedLocation != null) {
        _mapController.move(selectedLocation!, _zoomLevel);
      }
      setState(() {});
    }
  }

  void _zoomOut() {
    if (_zoomLevel > 2) {
      _zoomLevel -= 1.0;
      if (selectedLocation != null) {
        _mapController.move(selectedLocation!, _zoomLevel);
      }
      setState(() {});
    }
  }

  void _confirmLocation() {
    if (selectedLocation != null) {
      Navigator.of(context).pop({
        'latitude': selectedLocation!.latitude,
        'longitude': selectedLocation!.longitude,
        'address': selectedAddress,
      });
    } else {
      _showSnackBar('Please select a location');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[600],
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _locateCurrentPosition() async {
    _showSnackBar('Locating you...');

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services are disabled');
        _showSnackBar('Location services are disabled');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      print('Initial permission: $permission');
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        print('Requested permission: $permission');
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        print('Location permission denied or permanently denied');
        _showSnackBar('Location permission denied. Check app settings.');
        return;
      }

      print('Getting current position...');
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 20),
      );

      print('Got position: ${position.latitude}, ${position.longitude}');

      final newLocation = LatLng(position.latitude, position.longitude);

      // Get location name using Google geocoding for better accuracy
      String locationName = 'Your Location';
      try {
        final List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        ).timeout(const Duration(seconds: 10));

        if (placemarks.isNotEmpty) {
          final Placemark place = placemarks[0];
          locationName =
              '${place.street}, ${place.locality}, ${place.administrativeArea}';
          print('Address: $locationName');
        }
      } catch (e) {
        print('Geocoding error: $e');
      }

      // Update map and selection
      await _setLocation(newLocation);

      if (mounted) {
        _showSnackBar('You are at $locationName');
      }
    } catch (error) {
      print('Location error: $error');
      if (mounted) {
        _showSnackBar('Location error: $error');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Location'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFF0E9D63),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          // Map
          FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: selectedLocation ?? const LatLng(2.8127, 112.3277),
                    initialZoom: 1.0,
                    onTap: (tapPosition, latLng) => _onMapTap(latLng),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: _mapTilerUrl,
                      userAgentPackageName: 'dev.fleaflet.flutter_map.example',
                    ),
                    if (selectedLocation != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: selectedLocation!,
                            width: 80,
                            height: 80,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.location_pin,
                                  color: Colors.red[700],
                                  size: 40,
                                ),
                                const Text(
                                  'Selected',
                                  style: TextStyle(fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                        ],
                        rotate: true,
                      ),
                  ],
                ),
          // Zoom controls (left side)
          Positioned(
            left: 16,
            bottom: MediaQuery.of(context).size.height * 0.35,
            child: Column(
              children: [
                FloatingActionButton(
                  mini: true,
                  onPressed: _zoomIn,
                  backgroundColor: const Color(0xFF0E9D63),
                  child: const Icon(Icons.add, color: Colors.white),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  mini: true,
                  onPressed: _zoomOut,
                  backgroundColor: const Color(0xFF0E9D63),
                  child: const Icon(Icons.remove, color: Colors.white),
                ),
              ],
            ),
          ),
          // GPS button at bottom right
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.35,
            right: 16,
            child: FloatingActionButton(
              mini: true,
              onPressed: _locateCurrentPosition,
              backgroundColor: const Color(0xFF0E9D63),
              tooltip: 'Get Current Location',
              child: const Icon(Icons.my_location, color: Colors.white, size: 20),
            ),
          ),
          // Location info overlay at bottom
          Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status badge
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor().withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _getStatusColor()),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _getStatusIcon(),
                                size: 14,
                                color: _getStatusColor(),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                locationStatus,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _getStatusColor(),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (gpsAccuracy != null)
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                '±${gpsAccuracy!.toStringAsFixed(0)}m',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Selected Location',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Address with loading indicator
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            selectedAddress,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isLoadingAddress)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[600]!),
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (selectedLocation != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          '${selectedLocation!.latitude.toStringAsFixed(6)}, ${selectedLocation!.longitude.toStringAsFixed(6)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _confirmLocation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0E9D63),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Confirm Location',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (locationStatus) {
      case 'GPS verified':
        return Colors.green;
      case 'approximate':
        return Colors.orange;
      case 'Manual':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (locationStatus) {
      case 'GPS verified':
        return Icons.gps_fixed;
      case 'approximate':
        return Icons.gps_not_fixed;
      case 'Manual':
        return Icons.edit_location;
      default:
        return Icons.location_on;
    }
  }
}

