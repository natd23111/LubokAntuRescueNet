# Firebase Rules Update - Deployment Guide

## Issue Fixed
The seeding script was failing with `permission-denied` errors because the Firestore security rules were too restrictive for the seeding operations.

## Changes Made

### Updated Rules for Seeding Operations
The following collections now allow seeding (when authenticated):

1. **Aid Requests Collection**
   - `create` and `update` now support `canSeed()` function
   - Allows seeding to create aid requests with any user_id

2. **Emergency Reports Collection**
   - `create`, `update`, and `delete` now support `canSeed()` function
   - Allows seeding to create reports without strict user_id validation

3. **Notifications (User Subcollection)**
   - All operations (`write`, `create`, `delete`) now support `canSeed()` function
   - Allows seeding to create notifications for any user

4. **Warnings Collection (NEW)**
   - New collection rules added
   - Public read access
   - Admin and seeding write access

## Files Updated

1. **FIRESTORE_SECURITY_RULES.txt** - Updated existing rules
2. **firestore.rules** - New complete rules file for Firebase deployment

## How to Deploy

### Option 1: Using Firebase CLI (Recommended)

```bash
# Install Firebase CLI if not already installed
npm install -g firebase-tools

# Login to Firebase
firebase login

# Deploy the security rules
firebase deploy --only firestore:rules
```

### Option 2: Manual Update in Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project: "Lubok Antu RescueNet" (or your project name)
3. Navigate to **Firestore Database** → **Rules**
4. Copy the entire content from `firestore.rules` file
5. Paste it into the Rules editor
6. Click **Publish**

## Security Considerations

### Important: Remove Seeding Permissions After Deployment

The `canSeed()` function currently allows any authenticated user to bypass some security checks. This is temporary for development purposes.

**Before deploying to production:**

1. Comment out or remove the `canSeed()` function
2. Update the rules to remove `|| canSeed()` from all write operations
3. Implement proper role-based access control

### Recommended Changes Before Production

Replace:
```
allow write: if isAdmin() || canSeed();
```

With:
```
allow write: if isAdmin();
```

## Testing the Seeding

After deploying the rules, run the seeding function:

```dart
// In your app initialization
await FirebaseSeeder.seedDatabase();
```

Expected output:
```
✅ Firebase seeding completed successfully!
  ✓ Created admin user: admin@rescuenet.com
  ✓ Created citizen users...
  ✓ Created aid programs...
  ✓ Created emergency reports...
  ✓ Created aid requests...
  ✓ Created notifications...
  ✓ Created warnings...
```

## Clearing Data

To clear all seeded data:

```dart
await FirebaseSeeder.clearDatabase();
```

This will delete:
- All aid programs
- All aid requests
- All emergency reports
- All warnings
- All user profiles and their notifications
- All metadata

## Troubleshooting

### Still getting permission-denied errors?

1. Ensure rules are deployed correctly
   ```bash
   firebase rules:list
   ```

2. Verify Firebase Authentication is properly configured
   - Check that users are being created successfully in Auth
   - Confirm Firestore security rules are active (not in test mode)

3. Check Firestore in the Firebase Console
   - Navigate to **Firestore Database** → **Rules**
   - Verify the rules are showing the updated version with seeding support

### Rules deployment failed?

1. Install Firebase CLI
2. Login: `firebase login`
3. Verify project: `firebase projects:list`
4. Set project: `firebase use --add`
5. Deploy again: `firebase deploy --only firestore:rules`

## Reverting Changes

To revert to the previous rules:

1. Delete seeding support from rules
2. Run: `firebase deploy --only firestore:rules`
3. Or manually revert through Firebase Console
