import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../../providers/reports_provider.dart';
import '../../providers/auth_provider.dart';
import 'location_picker_screen.dart';
import '../../services/firebase_service.dart';

class SubmitEmergencyScreen extends StatefulWidget {
  final VoidCallback onBack;

  const SubmitEmergencyScreen({
    Key? key,
    required this.onBack,
  }) : super(key: key);

  @override
  State<SubmitEmergencyScreen> createState() => _SubmitEmergencyScreenState();
}

class _SubmitEmergencyScreenState extends State<SubmitEmergencyScreen> {
  bool showSuccess = false;
  bool isSubmitting = false;
  String? selectedEmergencyType;
  String? reportReference;
  List<XFile> selectedImages = [];
  List<Uint8List> selectedImageBytes = [];
  final ImagePicker _imagePicker = ImagePicker();
  double? selectedLatitude;
  double? selectedLongitude;

  final TextEditingController locationController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    locationController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  // Geocode location text to get coordinates
  Future<void> _geocodeLocationIfNeeded() async {
    // If coordinates already set via map picker, skip geocoding
    if (selectedLatitude != null && selectedLongitude != null) {
      return;
    }

    try {
      // Try to geocode the entered location text
      if (locationController.text.isNotEmpty) {
        final locations = await locationFromAddress(locationController.text);
        if (locations.isNotEmpty) {
          final location = locations.first;
          setState(() {
            selectedLatitude = location.latitude;
            selectedLongitude = location.longitude;
          });
          print('[Geocoding] Converted "${locationController.text}" to coordinates: ${location.latitude}, ${location.longitude}');
          return;
        }
      }
    } catch (e) {
      print('[Geocoding] Failed to geocode location text: $e');
    }

    // Fallback to current user GPS location
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showError('Location services disabled. Please enter location or use map picker.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        _showError('Location permission denied. Please use map picker to set location.');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 10));

      setState(() {
        selectedLatitude = position.latitude;
        selectedLongitude = position.longitude;
      });
      print('[Geocoding] Using current GPS location: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      print('[Geocoding] Failed to get GPS location: $e');
      _showError('Could not determine location. Please use map picker.');
    }
  }

  Future<void> _handleSubmit() async {
    // Validation
    if (selectedEmergencyType == null || selectedEmergencyType!.isEmpty) {
      _showError('Please select an emergency type');
      return;
    }
    if (locationController.text.isEmpty) {
      _showError('Please enter a location');
      return;
    }
    if (descriptionController.text.isEmpty) {
      _showError('Please provide a description');
      return;
    }

    setState(() => isSubmitting = true);

    try {
      // Auto-geocode location if no coordinates set yet
      await _geocodeLocationIfNeeded();

      // Validate that we have coordinates now
      if (selectedLatitude == null || selectedLongitude == null) {
        _showError('Could not determine location. Please use map picker.');
        setState(() => isSubmitting = false);
        return;
      }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final reportsProvider =
          Provider.of<ReportsProvider>(context, listen: false);

      final currentUser = authProvider.currentUser;
      if (currentUser == null) {
        _showError('Please sign in before submitting a report.');
        return;
      }

      // Get user info from profile
      final userName = authProvider.userName ?? 'Anonymous';
      final userIc = authProvider.userIc ?? '';
      final userPhone = authProvider.userPhone ?? '';
      
      // Create report object with user's profile data (exclude null values)
      final reportData = {
        'title': '${selectedEmergencyType} - ${locationController.text}',
        'type': selectedEmergencyType,
        'location': locationController.text,
        'description': descriptionController.text,
        'status': 'unresolved',
        'priority': 'high',
        'reporter_name': userName,
        'reporter_ic': userIc,
        'reporter_contact': userPhone,
        'date_reported': DateTime.now().toIso8601String(),
        'user_id': currentUser.uid,
        'latitude': selectedLatitude ?? 2.1234,
        'longitude': selectedLongitude ?? 112.5678,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Submit to Firebase (create report first)
      print('DEBUG: Submitting report with data: $reportData');
      final reportId = await reportsProvider.createEmergencyReport(reportData);
      print('DEBUG: Report creation returned: $reportId');

      if (reportId != null && mounted) {
        print('DEBUG: Report created successfully: $reportId');
        
        // If images were selected, upload them to Firebase Storage and update the report
        if (selectedImages.isNotEmpty) {
          print('DEBUG: Uploading ${selectedImages.length} images...');
          try {
            final firebase = FirebaseService();
            List<String> uploadedUrls = [];

            for (int i = 0; i < selectedImages.length; i++) {
              final xfile = selectedImages[i];
              final bytes = selectedImageBytes.length > i ? selectedImageBytes[i] : await xfile.readAsBytes();
              // derive extension from name if possible
              String ext = 'jpg';
              try {
                final parts = xfile.name.split('.');
                if (parts.length > 1) ext = parts.last;
              } catch (_) {}

              final storagePath = 'emergency_reports/$reportId/images/img_${i}_${DateTime.now().millisecondsSinceEpoch}.$ext';
              print('DEBUG: Uploading image $i to: $storagePath');
              final url = await firebase.uploadFile(storagePath, bytes);
              print('DEBUG: Image $i uploaded successfully: $url');
              uploadedUrls.add(url);
            }

            // Update Firestore document with image URLs (and first image for backward compatibility)
            if (uploadedUrls.isNotEmpty) {
              print('DEBUG: Updating report with ${uploadedUrls.length} image URLs');
              await FirebaseService().updateDocument('emergency_reports', reportId, {
                'image_urls': uploadedUrls,
                'image_url': uploadedUrls.first,
                'updated_at': DateTime.now().toIso8601String(),
              });
              print('DEBUG: Report updated with image URLs');
            }

            // Refresh provider to fetch updated docs
            await reportsProvider.fetchReports();
            if (Provider.of<AuthProvider>(context, listen: false).currentUser != null) {
              await reportsProvider.fetchMyReports();
            }
          } catch (e) {
            print('ERROR uploading images: $e');
            // Non-fatal: show error but proceed to show report success
            _showError('Uploaded report but failed to upload images: $e');
          }
        } else {
          print('DEBUG: No images to upload');
        }

        setState(() {
          showSuccess = true;
          reportReference = reportId;
        });

        // Clear form
        _clearForm();

        // Hide success message after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() => showSuccess = false);
            // Navigate back
            widget.onBack();
          }
        });
      } else {
        print('ERROR: Report creation failed or returned null');
        _showError('Failed to create report. Please try again.');
      }
    } catch (e) {
      print('ERROR submitting report: $e');
      if (mounted) {
        _showError('Error submitting report: $e');
        setState(() => isSubmitting = false);
      }
    } finally {
      if (mounted) {
        setState(() => isSubmitting = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _openLocationPicker() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const LocationPickerScreen(),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        locationController.text = result['address'] ?? '';
        selectedLatitude = result['latitude'];
        selectedLongitude = result['longitude'];
      });
      _showSuccess('Location selected: ${result['address']}');
    }
  }

  Future<void> _getCurrentLocation() async {
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

      // Open map picker with current location as initial position
      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => LocationPickerScreen(
            initialLatitude: position.latitude,
            initialLongitude: position.longitude,
          ),
        ),
      );

      if (result != null && mounted) {
        setState(() {
          locationController.text = result['address'] ?? '';
          selectedLatitude = result['latitude'];
          selectedLongitude = result['longitude'];
        });
        _showSuccess('Location selected: ${result['address']}');
      }
    } catch (e) {
      _showError('Error getting location: $e');
      print('Location error: $e');
    }
  }

  Future<void> _pickImage() async {
    try {
      // Check if already at max (3 images)
      if (selectedImages.length >= 3) {
        _showError('Maximum 3 images allowed. Remove an image to add more.');
        return;
      }

      final List<XFile>? pickedFiles = await _imagePicker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 80,
      );

      if (pickedFiles != null && pickedFiles.isNotEmpty) {
        int added = 0;
        int skipped = 0;

        for (var pickedFile in pickedFiles) {
          if (selectedImages.length + added >= 3) {
            skipped++;
            continue;
          }

          // Get file size in bytes (works on mobile and web)
          final int fileSizeInBytes = await pickedFile.length();
          final double fileSizeInMB = fileSizeInBytes / (1024 * 1024);

          if (fileSizeInMB > 5) {
            skipped++;
            continue;
          }

          // Read bytes for preview and uploading
          final bytes = await pickedFile.readAsBytes();

          setState(() {
            selectedImages.add(pickedFile);
            selectedImageBytes.add(bytes);
          });
          added++;
        }

        if (added == 0) {
          _showError('No valid images selected. Max 5MB per image.');
          return;
        }

        String message = 'Added $added image(s)';
        if (skipped > 0) message += ' ($skipped skipped)';
        _showSuccess(message);
      }
    } catch (e) {
      _showError('Error picking images: $e');
      print('Image picker error: $e');
    }
  }

  void _removeImage(int index) {
    setState(() {
      selectedImages.removeAt(index);
      selectedImageBytes.removeAt(index);
    });
    _showSuccess('Image removed');
  }

  void _clearForm() {
    setState(() {
      selectedEmergencyType = null;
      locationController.clear();
      descriptionController.clear();
      selectedLatitude = null;
      selectedLongitude = null;
      selectedImages.clear();
      selectedImageBytes.clear();
    });
  }

  String _getCurrentDate() {
    final now = DateTime.now();
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[now.month - 1]} ${now.day}, ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF059669),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: widget.onBack,
        ),
        title: const Text(
          'Submit Emergency Report',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Success Message
                  if (showSuccess)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        border: Border.all(color: Colors.green[200]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green[600],
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Report Submitted Successfully!',
                                  style: TextStyle(
                                    color: Colors.green[800],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'Your emergency report has been received. Reference: $reportReference',
                                  style: TextStyle(
                                    color: Colors.green[700],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Emergency Type
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Emergency Type',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Text(
                            ' *',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButton<String>(
                          value: selectedEmergencyType,
                          isExpanded: true,
                          underline: const SizedBox(),
                          hint: const Text('Select emergency type'),
                          items: [
                            'Flood',
                            'Fire',
                            'Accident',
                            'Medical Emergency',
                            'Landslide',
                            'Other',
                          ].map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedEmergencyType = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Location
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Location',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Text(
                            ' *',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: locationController,
                        decoration: InputDecoration(
                          hintText: 'Enter location or address',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFF059669),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _getCurrentLocation,
                          icon: const Icon(Icons.location_on, color: Colors.red),
                          label: const Text('Use Current Location on Map'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF059669),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Date
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Date',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Text(
                            ' *',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        enabled: false,
                        decoration: InputDecoration(
                          hintText: _getCurrentDate(),
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Auto-filled with current date',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Description
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Description',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Text(
                            ' *',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: descriptionController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Provide detailed description of the emergency',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFF059669),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Image Upload
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Upload Images',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Maximum 3 images, up to 5MB each',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Image Thumbnails
                      if (selectedImages.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            itemCount: selectedImages.length,
                            itemBuilder: (context, index) {
                              return Stack(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey[300]!),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Image.memory(
                                      selectedImageBytes[index],
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: GestureDetector(
                                      onTap: () => _removeImage(index),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      // Upload Button
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey[300]!,
                            width: 2,
                            style: BorderStyle.solid,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Icon(
                              Icons.cloud_upload,
                              size: 32,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Click to upload or drag and drop',
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              'PNG, JPG up to 5MB',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: selectedImages.length >= 3
                                  ? null
                                  : _pickImage,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[100],
                                foregroundColor: Colors.grey[700],
                              ),
                              child: Text(
                                selectedImages.length >= 3
                                    ? 'Max Images Reached'
                                    : 'Choose Images (${selectedImages.length}/3)',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Action Buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSubmitting ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Submit Report',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _clearForm,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      side: BorderSide(color: Colors.grey[300]!),
                    ),
                    child: Text(
                  'Clear / Reset',
                  style: TextStyle(color: Colors.grey[700]),
                ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: widget.onBack,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    side: BorderSide(color: Colors.grey[300]!),
                    ),
                    child: Text(
                      'Back',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
