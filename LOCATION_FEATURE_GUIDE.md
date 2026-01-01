# Use Current Location Feature - Implementation Guide

## Overview
The emergency report form now includes a "Use Current Location" feature that automatically captures the user's GPS coordinates and converts them to a readable address.

## How It Works

### Feature Components

1. **Geolocator Package** - Gets device GPS coordinates
2. **Geocoding Package** - Converts coordinates to addresses (reverse geocoding)
3. **Location Button** - Triggers the capture process
4. **Auto-fill Address** - Populates the location field

### User Experience

When citizen clicks "Use Current Location" button:

```
1. System checks if location services are enabled
   ↓
2. System requests location permissions (if needed)
   ↓
3. System gets device's GPS coordinates
   ↓
4. System converts coordinates to address (e.g., "123 Main St, 85000 Lubok Antu, Sarawak")
   ↓
5. Location field auto-fills with the address
   ↓
6. Success message shown to user
```

## Code Implementation

### Updated Files

#### 1. pubspec.yaml
Added two new packages:
```yaml
geolocator: ^11.0.0        # Gets GPS coordinates
geocoding: ^2.2.0          # Converts coordinates to addresses
```

#### 2. submit_emergency_screen.dart

**Imports added:**
```dart
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
```

**New method `_getCurrentLocation()`:**
- Checks if location services are enabled
- Requests location permissions
- Gets current GPS position
- Converts coordinates to address using reverse geocoding
- Falls back to coordinates if address lookup fails
- Updates the location text field

**New method `_showSuccess()`:**
- Displays success feedback to user

**Button implementation:**
```dart
TextButton.icon(
  onPressed: _getCurrentLocation,  // Now functional
  icon: const Text('📍'),
  label: const Text('Use Current Location'),
  style: TextButton.styleFrom(
    foregroundColor: const Color(0xFF059669),
  ),
),
```

## Permission Requirements

For the location feature to work, the app needs the following permissions:

### Android (android/app/src/main/AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

### iOS (ios/Runner/Info.plist)
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs access to your location to submit emergency reports with accurate location information.</string>
```

### Web (Not supported by geolocator by default)
- For web, you may need to implement a fallback or custom solution
- Currently, geolocator on web requires additional setup

## Feature Behavior

### Success Scenarios

**Scenario 1: Full Address Found**
```
Input: User clicks button
Output: "123 Main Street, 85000 Lubok Antu, Sarawak, Malaysia"
Status: Success message shown
```

**Scenario 2: Address Not Found (Fallback)**
```
Input: User clicks button in remote area
Output: "3.4856, 113.2481" (coordinates only)
Status: Success message shows "Location captured (coordinates)"
```

### Error Scenarios

**Scenario 1: Location Services Disabled**
```
Error: "Location services are disabled. Please enable them."
Action: User must enable location in device settings
```

**Scenario 2: Permission Denied**
```
Error: "Location permission was denied."
Action: User can tap button again to re-request
```

**Scenario 3: Permission Permanently Denied**
```
Error: "Location permissions are permanently denied. Open app settings to enable."
Action: User must manually enable in app settings
```

**Scenario 4: GPS Signal Lost**
```
Error: "Error getting location: [error details]"
Action: User should try in area with better GPS signal
```

## User Manual

### For Citizens

1. **Open emergency report form**
   - Navigate to "Submit Emergency Report" screen

2. **Fill in emergency type and description**
   - Select emergency type from dropdown
   - Enter description of incident

3. **Capture location**
   - Tap "📍 Use Current Location" button
   - Wait for location capture to complete (2-5 seconds)
   - Location field auto-fills with address

4. **Submit report**
   - Once location is captured, submit the report

### Permissions Prompts

**First time using:**
- System shows: "lar would like to access your location"
- User should tap "Allow" or "Allow While Using App"

**If permanently denied:**
- Go to Phone Settings → Apps → Lubok Antu RescueNet
- Tap "Permissions" → "Location"
- Select "Allow only while using the app"

## Technical Details

### Location Accuracy
- Uses `LocationAccuracy.high` for best accuracy
- Typically accurate within 5-10 meters
- Requires clear view of sky (GPS satellites)

### Address Format
The reverse geocoding returns addresses in this format:
```
[Street], [Postal Code] [City], [State]
```

Example:
```
Jalan Bukit, 85000 Lubok Antu, Sarawak
```

### Timeout Behavior
- Location request times out after 30 seconds if no GPS fix
- User will see error message
- Can retry by tapping button again

## Testing the Feature

### Test Case 1: Normal Operation (Indoors/Outdoor)
1. Tap "Use Current Location"
2. Verify location field fills with address
3. Verify success message appears

### Test Case 2: Permission Request
1. Clear app permissions for location
2. Tap "Use Current Location"
3. Verify permission prompt appears
4. Grant permission and verify location is captured

### Test Case 3: Location Services Disabled
1. Disable location in device settings
2. Tap "Use Current Location"
3. Verify error message about disabled services
4. Enable location and retry

### Test Case 4: Coordinates Fallback
1. Go to area with poor GPS signal (underground, dense forest)
2. Tap "Use Current Location"
3. Verify coordinates appear instead of address

### Test Case 5: Submit with Location
1. Capture location with button
2. Fill other fields (type, description)
3. Submit report
4. Verify in "My Reports" that location is saved correctly

## Performance Notes

- **Location capture**: 2-5 seconds typically
- **Address conversion**: 1-2 seconds typically
- **Total time**: 3-7 seconds from button tap to field population

For faster results, ensure:
- GPS is warmed up (phone has had location enabled for a few minutes)
- Clear view to sky (outdoors)
- 3G/4G/5G or WiFi available (for geocoding service)

## Fallback & Limitations

**Web Platform:**
- Geolocator has limited support on web
- May only work on HTTPS connections
- Browser permission prompt required

**Indoor Areas:**
- GPS accuracy decreases indoors
- May take longer to get fix
- Coordinate fallback recommended

**Remote Areas:**
- Address lookup may fail
- Coordinates will be used as fallback
- This is acceptable for emergency reports

## Future Enhancements

Possible improvements:
1. Add map view to select location manually
2. Add recent locations history
3. Add location markers for incident hotspots
4. Add weather data at location
5. Add estimated response time based on location
6. Add location sharing with response teams

## Troubleshooting

### Location button doesn't work
- Check device location services are enabled
- Grant app location permissions
- Ensure good GPS signal (outdoors recommended)
- Try app restart

### Location takes too long
- Wait for GPS fix (can take 10+ seconds cold start)
- Move to open area
- Ensure location services were recently enabled

### Wrong location captured
- GPS accuracy is 5-10m in good conditions
- Geocoding may return nearest address
- Manual entry recommended for precise locations

### Permission keeps asking
- Grant "Allow while using app" instead of "Only this time"
- Or grant permanent permission in app settings

## Summary

✅ **What You Get:**
- One-tap location capture
- Automatic coordinate-to-address conversion
- Fallback to coordinates if address lookup fails
- Permission handling with user feedback
- Error handling for all scenarios

✅ **Use Cases:**
- Quick location capture during emergencies
- Accurate GPS coordinates recorded
- Human-readable address for dispatch teams
- Works with existing location field

✅ **User Benefits:**
- No need to manually type location
- Faster report submission
- Accurate emergency response dispatch
- Handles poor GPS conditions gracefully
