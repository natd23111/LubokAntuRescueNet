# Firebase Rules Update Required

The Firestore security rules have been updated to fix the seeding permission issue.

## What Changed

Updated the rules to check `canSeed()` first before applying strict ownership checks:

**Before:**
```
allow create: if (isSignedIn() && user_id == auth.uid && valid_images) || canSeed();
```

**After:**
```
allow create: if canSeed() || (isSignedIn() && user_id == auth.uid && valid_images);
```

This ensures seeding operations bypass the strict user_id matching requirements.

## Deploy the Updated Rules

### Option 1: Firebase CLI (Recommended)
```bash
firebase deploy --only firestore:rules
```

### Option 2: Firebase Console
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select: lubok-antu-rescuenet
3. Go to: Firestore Database → Rules
4. Copy content from `firestore.rules` file
5. Paste and click Publish

## After Deployment

Run the seeding function again:
```dart
await FirebaseSeeder.seedDatabase();
```

Expected success message:
```
✅ Firebase seeding completed successfully!
  ✓ Created program...
  ✓ Created report...
  ✓ Created aid request...
  ✓ Created notification...
  ✓ Created warning...
```

## Files Updated
- `firestore.rules` - Complete rules file
- `FIRESTORE_SECURITY_RULES.txt` - Rules documentation
