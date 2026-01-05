import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../../l10n/app_localizations.dart';
import '../../providers/reports_provider.dart';
import '../../providers/auth_provider.dart';
import 'location_picker_screen.dart';
import '../../services/firebase_service.dart';

class SubmitEmergencyScreen extends StatefulWidget {
  final VoidCallback onBack;

  const SubmitEmergencyScreen({super.key, required this.onBack});

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
          print(
            '[Geocoding] Converted "${locationController.text}" to coordinates: ${location.latitude}, ${location.longitude}',
          );
          return;
        }
      }
    } catch (e) {
      print('[Geocoding] Failed to geocode location text: $e');
    }

    // Fallback to current user GPS location
    try {
      final l10n = AppLocalizations.of(context)!;
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showError(
          l10n.locationServicesDisabled,
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showError(
          l10n.locationPermissionDenied,
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 10));

      setState(() {
        selectedLatitude = position.latitude;
        selectedLongitude = position.longitude;
      });
      print(
        '[Geocoding] Using current GPS location: ${position.latitude}, ${position.longitude}',
      );
    } catch (e) {
      print('[Geocoding] Failed to get GPS location: $e');
      _showError('Could not determine location. Please use map picker.');
    }
  }

  Future<void> _handleSubmit() async {
    final l10n = AppLocalizations.of(context)!;
    // Validation
    if (selectedEmergencyType == null || selectedEmergencyType!.isEmpty) {
      _showError(l10n.pleaseSelectEmergencyType);
      return;
    }
    if (locationController.text.isEmpty) {
      _showError(l10n.pleaseEnterLocation);
      return;
    }
    if (descriptionController.text.isEmpty) {
      _showError(l10n.pleaseProvideDescription);
      return;
    }

    setState(() => isSubmitting = true);

    try {
      // Auto-geocode location if no coordinates set yet
      await _geocodeLocationIfNeeded();

      // Validate that we have coordinates now
      if (selectedLatitude == null || selectedLongitude == null) {
        _showError(l10n.couldNotDetermineLocation);
        setState(() => isSubmitting = false);
        return;
      }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final reportsProvider = Provider.of<ReportsProvider>(
        context,
        listen: false,
      );

      final currentUser = authProvider.currentUser;
      if (currentUser == null) {
        _showError(l10n.pleaseSignInBeforeSubmitting);
        return;
      }

      // Get user info from profile
      final userName = authProvider.userName ?? 'Anonymous';
      final userIc = authProvider.userIc ?? '';
      final userPhone = authProvider.userPhone ?? '';

      // Create report object with user's profile data (exclude null values)
      final reportData = {
        'title': '$selectedEmergencyType - ${locationController.text}',
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
              final bytes = selectedImageBytes.length > i
                  ? selectedImageBytes[i]
                  : await xfile.readAsBytes();
              // derive extension from name if possible
              String ext = 'jpg';
              try {
                final parts = xfile.name.split('.');
                if (parts.length > 1) ext = parts.last;
              } catch (_) {}

              final storagePath =
                  'emergency_reports/$reportId/images/img_${i}_${DateTime.now().millisecondsSinceEpoch}.$ext';
              print('DEBUG: Uploading image $i to: $storagePath');
              final url = await firebase.uploadFile(storagePath, bytes);
              print('DEBUG: Image $i uploaded successfully: $url');
              uploadedUrls.add(url);
            }

            // Update Firestore document with image URLs (and first image for backward compatibility)
            if (uploadedUrls.isNotEmpty) {
              print(
                'DEBUG: Updating report with ${uploadedUrls.length} image URLs',
              );
              await FirebaseService()
                  .updateDocument('emergency_reports', reportId, {
                'image_urls': uploadedUrls,
                'image_url': uploadedUrls.first,
                'updated_at': DateTime.now().toIso8601String(),
              });
              print('DEBUG: Report updated with image URLs');
            }

            // Refresh provider to fetch updated docs
            await reportsProvider.fetchReports();
            if (Provider.of<AuthProvider>(context, listen: false).currentUser !=
                null) {
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
        _showError(l10n.failedToCreateReport);
      }
    } catch (e) {
      print('ERROR submitting report: $e');
      if (mounted) {
        _showError('${l10n.errorSubmittingReport} $e');
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
      MaterialPageRoute(builder: (context) => const LocationPickerScreen()),
    );

    if (result != null && mounted) {
      setState(() {
        locationController.text = result['address'] ?? '';
        selectedLatitude = result['latitude'];
        selectedLongitude = result['longitude'];
      });
      final l10n = AppLocalizations.of(context)!;
      _showSuccess('${l10n.locationSelected}: ${result['address']}');
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final l10n = AppLocalizations.of(context)!;
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showError(l10n.locationServicesAreDisabled);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        _showError(l10n.locationPermissionWasDenied);
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        _showError(
          l10n.locationPermissionsPermanentlyDenied,
        );
        return;
      }

      final Position position =
      await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () =>
        throw TimeoutException('Location request timed out'),
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
        final l10n = AppLocalizations.of(context)!;
        setState(() {
          locationController.text = result['address'] ?? '';
          selectedLatitude = result['latitude'];
          selectedLongitude = result['longitude'];
        });
        _showSuccess('${l10n.locationSelected}: ${result['address']}');
      }
    } catch (e) {
      final l10n = AppLocalizations.of(context)!;
      _showError('${l10n.errorGettingLocation}: $e');
      print('Location error: $e');
    }
  }

  Future<void> _pickImage() async {
    try {
      final l10n = AppLocalizations.of(context)!;
      // Check if already at max (3 images)
      if (selectedImages.length >= 3) {
        _showError(l10n.maximum3ImagesAllowed);
        return;
      }

      final List<XFile> pickedFiles = await _imagePicker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 80,
      );

      if (pickedFiles.isNotEmpty) {
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
          _showError(l10n.noValidImagesSelected);
          return;
        }

        String message = added > 0 ? l10n.addedImages('$added') : '';
        if (added > 0 && skipped > 0) {
          message = '${l10n.addedImages('$added')} ($skipped ${l10n.addedImagesSkipped})';
        }
        _showSuccess(message);
      }
    } catch (e) {
      final l10n = AppLocalizations.of(context)!;
      _showError('Error picking images: $e');
      print('Image picker error: $e');
    }
  }

  void _removeImage(int index) {
    setState(() {
      selectedImages.removeAt(index);
      selectedImageBytes.removeAt(index);
    });
    final l10n = AppLocalizations.of(context)!;
    _showSuccess(l10n.imageRemoved);
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
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[now.month - 1]} ${now.day}, ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
        title: Text(
          l10n.submitEmergency,
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
                                  l10n.reportSubmittedSuccessfully,
                                  style: TextStyle(
                                    color: Colors.green[800],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  l10n.yourEmergencyReportHasBeenReceived(reportReference ?? 'N/A'),
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
                            l10n.emergencyTypeLabel,
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Text(' *', style: TextStyle(color: Colors.red)),
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
                          hint: Text(l10n.selectEmergencyType),
                          items: [
                            DropdownMenuItem(value: 'Flood', child: Text(l10n.floodOption)),
                            DropdownMenuItem(value: 'Fire', child: Text(l10n.fireOption)),
                            DropdownMenuItem(value: 'Accident', child: Text(l10n.accidentOption)),
                            DropdownMenuItem(value: 'Medical Emergency', child: Text(l10n.medicalEmergencyOption)),
                            DropdownMenuItem(value: 'Landslide', child: Text(l10n.landslideOption)),
                            DropdownMenuItem(value: 'Other', child: Text(l10n.otherOption)),
                          ],
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
                            l10n.locationLabel,
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Text(' *', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: locationController,
                        decoration: InputDecoration(
                          hintText: l10n.enterLocationOrAddress,
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
                          icon: const Icon(
                            Icons.location_on,
                            color: Colors.red,
                          ),
                          label: Text(l10n.useCurrentLocationOnMap),
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
                            l10n.dateLabel,
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Text(' *', style: TextStyle(color: Colors.red)),
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
                        l10n.autoFilledWithCurrentDate,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
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
                            l10n.descriptionLabel,
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Text(' *', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: descriptionController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: l10n.provideDetailedDescription,
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
                        l10n.uploadImages,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        l10n.maximumImagesConstraint,
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                      const SizedBox(height: 12),
                      // Image Thumbnails
                      if (selectedImages.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
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
                                      border: Border.all(
                                        color: Colors.grey[300]!,
                                      ),
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
                        width: double.infinity,
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
                              l10n.clickToUploadOrDragDrop,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            Text(
                              l10n.pngJpgUpTo5MB,
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
                                    ? l10n.maxImagesReached
                                    : l10n.chooseImages('${selectedImages.length}', '3'),
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
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
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
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    )
                        : Text(
                      l10n.submitReport,
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
                      l10n.clearOrReset,
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
                      l10n.back,
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
