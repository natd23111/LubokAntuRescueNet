# Firebase Messaging Web Platform - Fix Guide

## Error
```
[firebase_messaging/failed-service-worker-registration] Messaging: We are unable to register the default service worker. Failed to register a ServiceWorker for scope ('http://localhost:58101/firebase-cloud-messaging-push-scope') with script ('http://localhost:58101/firebase-messaging-sw.js'): The script has an unsupported MIME type ('text/html').
```

## Root Cause
The `firebase-messaging-sw.js` service worker file was missing from the `web/` directory. Firebase requires this file to handle background messages on the web platform.

## What Was Fixed

### 1. Created Missing Service Worker File
**File:** `web/firebase-messaging-sw.js`

This file:
- Initializes Firebase in the service worker context
- Handles background messages when the app is not in focus
- Shows notifications to users
- Handles notification clicks
- Re-directs to the app when notification is clicked

### 2. Service Worker Contents

The `firebase-messaging-sw.js` file includes:
```javascript
// Imports Firebase libraries
importScripts('https://www.gstatic.com/firebasejs/9.23.0/firebase-app.js');
importScripts('https://www.gstatic.com/firebasejs/9.23.0/firebase-messaging.js');

// Handles background messages
messaging.onBackgroundMessage((payload) => { ... });

// Handles notification clicks
self.addEventListener('notificationclick', function(event) { ... });
```

## Verification Steps

### Step 1: Verify File Exists
```bash
# Check that the file exists
ls web/firebase-messaging-sw.js
# Or on Windows
dir web\firebase-messaging-sw.js
```

### Step 2: Run the App on Web
```bash
flutter run -d chrome
```

### Step 3: Check Browser Console
1. Open DevTools: F12
2. Go to Application tab
3. Check Service Workers section
4. Verify: "firebase-messaging-sw" is listed and active

## Important Notes

### Web Platform Only
This issue only affects the web platform. Mobile (Android/iOS) uses different notification mechanisms.

### Service Worker Registration
- Service workers are only registered for HTTPS (or localhost for development)
- The browser will serve the `.js` file with `application/javascript` MIME type automatically
- Flutter's dev server handles MIME types correctly

### Firebase Versions
The service worker uses Firebase v9.23.0. Check your `web/index.html` to ensure:
1. It's consistent with your `firebase_messaging` package version
2. Update if needed to match your setup

## Troubleshooting

### Still Getting MIME Type Error?

**Solution 1: Clear Browser Cache**
```bash
# On Chrome DevTools
Cmd+Shift+Delete (Mac) or Ctrl+Shift+Delete (Windows)
# Select "All time" and clear cache
```

**Solution 2: Hard Refresh**
```
Chrome: Ctrl+Shift+R (Windows) or Cmd+Shift+R (Mac)
Firefox: Ctrl+F5 (Windows) or Cmd+Shift+R (Mac)
```

**Solution 3: Restart Dev Server**
```bash
# Stop Flutter (Ctrl+C)
# Clear build
flutter clean
# Run again
flutter run -d chrome
```

### Service Worker Not Registering?

1. Verify file exists: `web/firebase-messaging-sw.js`
2. Check browser console for errors (F12)
3. Ensure HTTPS or localhost is being used
4. Check Firebase configuration in the service worker

### Test Notifications

After successful service worker registration:

1. From Dart code:
```dart
// Request notification permission
final notificationSettings = await FirebaseMessaging.instance.requestPermission();
print('Notification permission: ${notificationSettings.authorizationStatus}');
```

2. Send test message from Firebase Console:
   - Go to Cloud Messaging
   - Create a test notification
   - Send to your device token

## Files Modified

| File | Action | Purpose |
|------|--------|---------|
| `web/firebase-messaging-sw.js` | Created | Service worker for handling FCM |
| `web/index.html` | No change | Already correctly configured |
| `pubspec.yaml` | No change | Dependencies already correct |

## Next Steps

1. Run the app on web platform
2. Check browser DevTools (F12 → Application → Service Workers)
3. Verify service worker is registered
4. Test notifications through Firebase Console
5. Monitor console for any errors

## Firebase Console Testing

To send test notifications:

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select project: `lubok-antu-rescuenet`
3. Navigate to: Cloud Messaging
4. Click: "New campaign"
5. Choose: "Send test message"
6. Paste your device token
7. Click: "Test"

Expected result: Notification appears even if app is in background

## Additional Resources

- [Firebase Cloud Messaging Web Docs](https://firebase.google.com/docs/cloud-messaging/js/receive)
- [Service Workers MDN](https://developer.mozilla.org/en-US/docs/Web/API/Service_Worker_API)
- [Flutter Web Platform](https://flutter.dev/multi-platform/web)

---

**Status:** ✅ Service Worker Configured
**Platform:** Web (Chrome, Firefox, Safari)
**Last Updated:** January 4, 2026
