# How to Login as Admin

## Option 1: Use Hardcoded Admin Accounts (Current Setup)

The system has these **pre-authorized admin emails**:
- `admin@rescuenet.com`
- `admin123@example.com`

### Steps:

1. **Register an account** with one of these emails:
   - Email: `admin@rescuenet.com`
   - Password: `password123`
   - Name: `Admin User`

2. **Login screen:**
   - Click the **"Admin"** button (not Citizen)
   - Enter email: `admin@rescuenet.com`
   - Enter password: `password123`
   - Click "Sign In"

3. **You should now see:**
   - Admin Dashboard (instead of Citizen Dashboard)
   - Manage Aid Programs
   - Manage Reports
   - Manage Users

---

## Option 2: Add Your Own Admin Email

Edit the login screen to add your email to admin list:

File: `lib/screens/auth/login_screen.dart`

Find this section:
```dart
const List<String> adminEmails = [
  'admin@rescuenet.com',
  'admin123@example.com',
];
```

Add your email:
```dart
const List<String> adminEmails = [
  'admin@rescuenet.com',
  'admin123@example.com',
  'your-email@example.com',  // Add this line
];
```

Then register with your email and login as admin.

---

## Option 3: Set Admin Role in Firebase (Advanced)

You can manually set the role in Firestore:

1. Go to Firebase Console
2. Firestore Database → Collections
3. Open `users` collection
4. Find your user document
5. Edit the `role` field → Change from `"citizen"` to `"admin"`
6. Save

Next time you login, you'll be admin.

---

## Testing Admin Features

Once logged in as admin, you should see:

✅ **Admin Dashboard** with:
- Manage Aid Programs (Create, Edit, Delete)
- Manage Emergency Reports
- View Analytics
- User Management

---

## Quick Test Steps

1. Open app in Chrome
2. Click "Don't have an account?"
3. Register with:
   - Name: `Test Admin`
   - IC: `950101-12-1234`
   - Phone: `0123456789`
   - Email: `admin@rescuenet.com`
   - Password: `password123`

4. After registration, go back to login
5. Click **"Admin"** button (green highlight)
6. Enter: `admin@rescuenet.com` / `password123`
7. Click "Sign In"
8. You should see Admin Dashboard! ✅

---

## Need a Different Admin Email?

Edit `lib/screens/auth/login_screen.dart` line ~28 and add your email to the list:

```dart
const List<String> adminEmails = [
  'admin@rescuenet.com',
  'admin123@example.com',
  'your-email-here@example.com',  // Add your email
];
```

Save and Flutter will hot-reload automatically.
