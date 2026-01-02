# Notification System Testing Guide

## What Was Fixed
The NotificationsProvider now listens to Firebase auth state changes and **initializes listeners AFTER user logs in**, instead of at app startup when no user is authenticated.

## How It Works Now
1. **App starts** → NotificationsProvider created, listening to auth state changes
2. **User logs in** → Firebase auth state changes to logged-in user
3. **NotificationsProvider detects login** → Initializes Firestore listeners
4. **Listeners activate** → Watching for report/aid request status changes in Firestore
5. **Admin updates report status** → Listener detects change, creates notification
6. **Notification displayed** → Local popup shows on citizen's phone

## Testing Steps

### Step 1: Run the App
```bash
flutter run
```

### Step 2: Login as Citizen
- Open the app in the citizen app (Flutter)
- Log in with a citizen account
- **Check console** for: `👤 User logged in, initializing notifications listener...`
- **Check console** for: `✅ Notification listeners initialized`

### Step 3: Admin Updates Report Status
**Using Laravel Admin Dashboard:**
1. Open [Admin Dashboard](http://localhost:8000/admin) or your admin web interface
2. Navigate to Emergency Reports
3. Find a report from your logged-in citizen
4. Change the status to one of: `pending`, `in_progress`, `completed`, `resolved`
5. Save the changes

**Or via Firebase Console:**
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project → Firestore
3. Find the `emergency_reports` collection
4. Edit a report and change the `status` field
5. Save

### Step 4: Verify Notification Received
- **Expected result:** Within 2 seconds, a notification popup appears on the citizen's phone
- **Check console for:**
  ```
  🔔 Notification displayed: Your report status has been updated
  ```

### Step 5: Check Notification Details
- Tap the notification to see full details
- Check the Notifications screen to see the notification in the history

## Troubleshooting

### No Auth State Change Message
**Problem:** Console doesn't show `👤 User logged in...`
- The AuthProvider might not be properly connected
- Check that NotificationsProvider is provided in main.dart

### Listeners Initialized But No Notification
**Problem:** Console shows `✅ Notification listeners initialized` but no notification on update
- Check that you're updating a report for the logged-in user
- Verify the `user_id` field in Firestore matches the logged-in user's UID
- Check browser console in Firebase to ensure write was successful

### "Notification displayed" but No Popup
**Problem:** Console shows notification was sent but user didn't see it
- iOS: Check that notifications are enabled in Settings > App Name > Notifications
- Android: Check that notifications are enabled in App Info > Notifications
- Try restarting the app
- Check notification center/notification panel on phone

### Still Not Working?

**Check These in Order:**

1. **Verify Listener is Active:**
   - Add this to a test button in the app:
   ```dart
   print('📊 Current user: ${FirebaseAuth.instance.currentUser?.uid}');
   print('📊 Notifications listener active: ${_notificationsProvider._notifications.isNotEmpty}');
   ```

2. **Verify Report Document Structure:**
   - In Firebase Console, check emergency_reports/{reportId}:
   ```
   ✅ Should have: user_id (matches logged-in user)
   ✅ Should have: status (one of the recognized values)
   ✅ Should be readable by the user
   ```

3. **Verify Firestore Rules:**
   - Users should be able to read their own reports:
   ```
   match /emergency_reports/{document=**} {
     allow read: if request.auth.uid == resource.data.user_id;
   }
   ```

4. **Check Notification Permissions:**
   - iOS 13+: Settings > Your App > Notifications > Allow Notifications (ON)
   - Android 13+: Settings > Apps > Your App > Notifications (ON)

5. **Test End-to-End:**
   - Manually create a notification in Firestore:
   ```
   Collection: users/{userId}/notifications
   Document: test_{timestamp}
   Fields: title, body, type: "test", timestamp: now
   ```
   - This should trigger an immediate local notification

## Expected Console Output

**On Login:**
```
👤 User logged in, initializing notifications listener...
✅ Notification listeners initialized
```

**When Admin Updates Report:**
```
🔔 Notification displayed: Your report status has been updated
```

**When Pulling in Notification History:**
```
✅ Notifications loaded: 5 notifications
```

## File Changes Made
- `lib/providers/notifications_provider.dart` - Now initializes listeners after auth state changes

## Related Files
- [NotificationsProvider](lib/providers/notifications_provider.dart) - Real-time listener management
- [Notification Model](lib/models/notification.dart) - Notification data structure
- [PushNotificationService](lib/services/push_notification_service.dart) - Firebase Cloud Messaging setup
