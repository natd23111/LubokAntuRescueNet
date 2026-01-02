# Telegram Bot Alerts Setup Guide

## Overview
This guide will walk you through setting up Telegram alerts for the RescueNet system using Firebase Cloud Functions.

## Prerequisites
- Telegram account
- Firebase project with Firestore
- Flutter app configured with Firebase
- Node.js 18+ installed locally

## Step 1: Create Telegram Bot with BotFather

1. Open Telegram and search for **@BotFather**
2. Send the command: `/newbot`
3. BotFather will ask for:
   - **Bot name**: e.g., "Lubok Antu RescueNet Bot"
   - **Username**: e.g., `@rescuenet_bot` (must be unique and end with "_bot")

4. BotFather will respond with your **Bot Token**:
   ```
   Use this token to access the HTTP API:
   1234567890:ABCDEFghijklmnopqrstuvwxyz
   ```

5. Save this token securely - you'll need it for Cloud Functions

## Step 2: Deploy Cloud Functions

### 2a. Initialize Firebase Functions locally (if not already done)

```bash
npm install -g firebase-tools
firebase login
cd "e:\Unimas\Year 4\SELab\Project\Lubok Antu RescueNet"
firebase init functions
```

### 2b. Install dependencies

```bash
cd firebase-functions
npm install
```

### 2c. Add Bot Token to Environment Variables

Create a `.env.local` file in the `firebase-functions` directory:

```
TELEGRAM_BOT_TOKEN=your_bot_token_here
```

Or use Firebase config:

```bash
firebase functions:config:set telegram.bot_token="your_bot_token_here"
```

### 2d. Deploy functions

```bash
firebase deploy --only functions
```

This will deploy:
- `sendTelegramAlert` - Triggered automatically when notifications are created
- `telegramWebhook` - Receives messages from the bot
- `health` - Health check endpoint

## Step 3: Firestore Security Rules Update

Update your Firestore security rules to include Telegram fields:

```firestore
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    function isSignedIn() {
      return request.auth != null;
    }
    
    // Users collection
    match /users/{userId} {
      allow read: if request.auth.uid == userId;
      allow write: if request.auth.uid == userId;
      allow update: if request.auth.uid == userId && 
        // Allow updating Telegram fields
        (request.resource.data.keys().hasAll(['telegramChatId', 'telegramLinked']) ||
         request.resource.data.keys().hasAny(['telegramChatId', 'telegramLinked', 'telegramNotificationsEnabled', 'telegramVerificationCode']));
      
      // Notifications subcollection
      match /notifications/{notificationId} {
        allow read: if request.auth.uid == userId;
        allow create: if request.auth.uid == userId;
        allow write: if false; // Cloud Functions will manage
      }
    }
  }
}
```

## Step 4: Configure Telegram Webhook (Optional)

To receive bot updates, set the webhook in Cloud Functions:

```bash
curl -X POST \
  "https://api.telegram.org/bot{YOUR_BOT_TOKEN}/setWebhook" \
  -d "url={YOUR_CLOUD_FUNCTION_URL}/telegramWebhook"
```

Replace:
- `{YOUR_BOT_TOKEN}` with your bot token
- `{YOUR_CLOUD_FUNCTION_URL}` with your deployed function URL (from Firebase Console)

## Step 5: Flutter App Configuration

### 5a. Import TelegramService

The TelegramService is already implemented in:
- `lib/services/telegram_service.dart`

### 5b. User Linking Flow

When a user clicks "Connect Telegram" in Notification Settings:

1. **Get Verification Code**: `TelegramService().getVerificationCode()`
   - Generates 6-digit code
   - Stores in Firestore with 15-minute expiry
   - Shows code in dialog

2. **User Action in Telegram**:
   - User searches for `@rescuenet_bot`
   - Sends `/start` to get instructions
   - Sends the verification code

3. **Complete Linking**: `TelegramService().linkTelegramAccount(chatId, verificationCode)`
   - Validates code
   - Stores `telegramChatId` in user's Firestore document
   - Sets `telegramLinked: true`

### 5c. Automatic Alert Sending

When a notification is created in Firestore:
```dart
// In notifications_provider.dart when creating notification
await _firestore
  .collection('users')
  .doc(userId)
  .collection('notifications')
  .add({
    'type': 'report_status',
    'data': {
      'reportId': 'ER20260033',
      'reportType': 'emergency',
      'newStatus': 'in-progress',
      'detailedInfo': '...'
    },
    'createdAt': FieldValue.serverTimestamp(),
  });
// Cloud Function automatically sends Telegram message!
```

## Step 6: Testing

### 6a. Test Manual Message (Using Firebase Console)

```javascript
// Run in Firebase Cloud Functions console
const result = await admin.firestore()
  .collection('users')
  .doc('test_user_id')
  .set({
    telegramChatId: '123456789',
    telegramLinked: true
  });

// Create notification to trigger function
await admin.firestore()
  .collection('users')
  .doc('test_user_id')
  .collection('notifications')
  .add({
    type: 'report_status',
    data: {
      reportId: 'ER20260001',
      reportType: 'emergency',
      newStatus: 'in-progress'
    },
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  });
```

### 6b. Test from Flutter App

1. Open app in emulator/device
2. Go to Notification Settings
3. Click "Connect Telegram"
4. Copy the code from dialog
5. Open Telegram, search `@rescuenet_bot`
6. Send `/start`
7. Send the code
8. Back in app, paste chat ID and click "Link Account"
9. Should see success message

### 6c. Check Cloud Function Logs

```bash
firebase functions:log
```

Or in Firebase Console:
- Go to Cloud Functions
- Click on `sendTelegramAlert`
- View Logs tab

Look for messages like:
```
📬 Processing notification for user: xyz
✅ Telegram message sent successfully
```

## Step 7: Production Deployment Checklist

- [ ] Bot token added to Firebase config
- [ ] Cloud Functions deployed
- [ ] Firestore security rules updated
- [ ] Webhook URL set (if using updates)
- [ ] Test Telegram linking works end-to-end
- [ ] Test notification creation triggers Telegram message
- [ ] Monitor Cloud Function logs for errors
- [ ] Rate limiting configured in TelegramService (optional)

## Troubleshooting

### "Bot token not configured"
- Check Firebase config: `firebase functions:config:get`
- Verify `TELEGRAM_BOT_TOKEN` is set
- Redeploy: `firebase deploy --only functions`

### "Telegram API error 401"
- Bot token is incorrect
- Verify token in Firebase config
- Get new token from @BotFather if needed

### "NavigationKey is null"
- This occurs in the notification tap handler, not Telegram
- Ensure `navigationKey` is initialized in `main.dart`

### Notifications not creating in Firestore
- Check app has `write` permission to `users/{uid}/notifications`
- Verify user is authenticated
- Check Firestore security rules allow write

### Cloud Function not triggering
- Verify function deployed: `firebase functions:list`
- Check Firestore trigger path: `users/{userId}/notifications/{notificationId}`
- Monitor logs for errors

### Telegram message not sending
- Check user has `telegramChatId` in Firestore
- Verify `telegramLinked: true`
- Check Cloud Function logs
- Test API manually: `curl https://api.telegram.org/bot{TOKEN}/sendMessage -d 'chat_id=123&text=hello'`

## File Reference

- **Backend/Cloud Functions**: `firebase-functions/index.js`
- **Flutter Service**: `lib/services/telegram_service.dart`
- **UI Component**: `lib/screens/notifications/notification_settings_screen.dart`
- **Dialog**: `lib/screens/notifications/telegram_linking_dialog.dart`
- **Security Rules**: Apply to Firestore in Firebase Console

## API Endpoints

All endpoints are in Cloud Functions:

| Function | Trigger | Purpose |
|----------|---------|---------|
| `sendTelegramAlert` | Firestore onCreate | Send alert when notification created |
| `telegramWebhook` | HTTPS POST | Receive bot messages |
| `health` | HTTPS GET | Health check |

## Next Steps

1. Deploy Cloud Functions
2. Test bot linking in app
3. Create test notification to verify Telegram message
4. Monitor production logs
5. Adjust message formatting as needed

---

**Created**: January 3, 2026  
**Last Updated**: January 3, 2026
