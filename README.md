# 📱 Lubok Antu RescueNet (LAR)

Lubok Antu RescueNet (LAR) is a mobile-based emergency and community aid reporting system designed for residents of Lubok Antu and managed by Pusat Khidmat Lubok Antu.

This repository contains the **Flutter mobile frontend application** with Firebase backend integration. The Laravel backend has been separated into a standalone repository.

```
LubokAntuRescueNet/
├── Lar-Frontend/          → Flutter Mobile Application
├── firebase-functions/    → Firebase Cloud Functions
└── documentation/         → Setup guides & architecture
```

---

## 🚀 Project Overview

### 📱 Mobile App (Flutter)

### ☁️ Backend Architecture (Firebase)
- ✅ Firebase Authentication (Email/Password)
- ✅ Cloud Firestore (Real-time database)
- ✅ Firebase Cloud Messaging (Push notifications)
- ✅ Firebase Storage (Image uploads)
- ✅ Firestore Security Rules (Role-based access control)

---

## 🛠️ Tech Stack

| Layer | Technologies |
|-------|--------------|
| **Frontend** | Flutter 3.9.2+, Dart, Provider state management |
| **Mobile Platforms** | Android, iOS, Web |
| **Backend** | Firebase (Firestore, Auth, Storage, Messaging) |
| **APIs** | Google Maps, Gemini, Firebase |
| **Services** | Location services, Push notifications, Image processing |

---

## 📋 Quick Start

### Prerequisites
- Flutter 3.9.2 or higher
- Dart SDK
- Firebase project configured
- Git

### 1️⃣ Clone & Setup

```bash
git clone <repository-url>
cd "Lubok Antu RescueNet"
cd Lar-Frontend
flutter pub get
```

### 2️⃣ Configure Firebase

1. Create a Firebase project at [firebase.google.com](https://firebase.google.com)
2. Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
3. Place files in the correct directories:
   - Android: `android/app/google-services.json`
   - iOS: `ios/Runner/GoogleService-Info.plist`
4. Update Firebase configuration in `lib/firebase_options.dart`

### 3️⃣ Run the App

```bash
# Android
flutter run -d android

# iOS
flutter run -d ios

# Web
flutter run -d chrome
```

---

## 📁 Project Structure

```
Lar-Frontend/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── app.dart                     # App configuration
│   ├── screens/                     # UI screens
│   │   ├── auth/                   # Login/Register
│   │   ├── citizen/                # Citizen features
│   │   ├── admin/                  # Admin features
│   │   └── ...
│   ├── providers/                   # State management (Provider pattern)
│   ├── services/                    # Business logic
│   │   ├── firebase_service.dart   # Firebase operations
│   │   ├── api_service.dart        # REST API calls
│   │   ├── location_service.dart   # GPS & location
│   │   └── ...
│   ├── models/                      # Data models
│   ├── widgets/                     # Reusable UI components
│   ├── scripts/                     # Utilities (seeding, migrations)
│   ├── constants/                   # App constants
│   ├── config/                      # Configuration files
│   └── utils/                       # Helper functions
├── assets/                          # Images, icons
├── pubspec.yaml                     # Dependencies
└── ...
```

---

## 🔑 Key Features

### Emergency Reporting
- Submit emergency incidents with photos
- Real-time location tracking
- Map picker for precise location selection
- Automatic geocoding of addresses
- Status tracking and admin remarks

### Aid Programs
- Browse available aid/assistance programs
- Advanced filtering (category, amount, date range)
- Search functionality
- Program eligibility criteria
- Real-time status updates

### Notifications
- Real-time push notifications (FCM)
- Local notification support
- Notification history
- Customizable notification preferences

### User Management
- Email/password authentication via Firebase
- User profile management
- Role-based access (Admin vs Resident)
- Account status tracking

### Location Services
- GPS location acquisition
- Address geocoding/reverse-geocoding
- Interactive map picker
- Location validation within service area

---

## 🔧 Development Workflow

### Running Tests
```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage
```

### Code Quality
```bash
# Analyze code
flutter analyze

# Format code
dart format lib/

# Run linter
flutter pub run effective_dart:rules
```

### Build Release APK/APP
```bash
# Android APK
flutter build apk

# Android App Bundle
flutter build appbundle

# iOS
flutter build ios
```

---

## 📚 Documentation

Complete documentation available:

| Document | Purpose |
|----------|---------|
| [Firebase Setup Guide](FIREBASE_MIGRATION_GUIDE.md) | Firebase configuration & deployment |
| [Aid Program System](README_AID_PROGRAM_SYSTEM.md) | Aid programs CRUD operations |
| [Filtering Guide](FILTERING_REFERENCE_GUIDE.md) | Search & filter implementation |
| [Notifications Setup](NOTIFICATION_TESTING_GUIDE.md) | Push notifications configuration |
| [Admin Dashboard](ADMIN_DASHBOARD_SETUP.md) | Web admin interface guide |
| [Project Analysis](PROJECT_ANALYSIS_STRENGTHS_WEAKNESSES.md) | Complete strengths & weaknesses analysis |

---

## 🔐 Security Considerations

### Current Security Measures
- ✅ Firebase Authentication with email/password
- ✅ Firestore Security Rules (role-based access)
- ✅ Image validation (size, format)
- ✅ Location bounds validation
- ✅ Input validation on all forms

### Recommended Improvements
- 🟡 Add end-to-end encryption for sensitive data
- 🟡 Implement token refresh mechanism
- 🟡 Add biometric authentication
- 🟡 Enhance password complexity requirements
- 🟡 Add audit logging for admin actions

---

## 🚀 Deployment

### Firebase Deployment
```bash
cd firebase-functions
npm install
firebase deploy --only functions,firestore:rules
```

### Flutter App Distribution
- **Android**: Upload to Google Play Store
- **iOS**: Upload to Apple App Store
- **Web**: Deploy to Firebase Hosting or custom server

See [FIREBASE_MIGRATION_GUIDE.md](FIREBASE_MIGRATION_GUIDE.md) for detailed deployment steps.

---

## 🐛 Troubleshooting

### Common Issues

**Firebase Connection Fails**
```bash
# Clear build cache
flutter clean
flutter pub get
flutter run
```

**Location Permission Issues**
- Ensure location permissions are granted in app settings
- Check location services are enabled on device
- Review [WEB_LOCATION_FIX.md](WEB_LOCATION_FIX.md) for web-specific fixes

**Push Notification Issues**
- Verify FCM configuration in Firebase Console
- Check [WEB_FIREBASE_MESSAGING_FIX.md](WEB_FIREBASE_MESSAGING_FIX.md) for web platform issues
- Ensure service worker is properly configured for web

---

## 📊 Project Status

**Current Phase**: Development with Production Features  
**Overall Rating**: 7/10 - Good foundation with improvement opportunities

### Production Readiness
- 🟢 **Ready for Beta**: Core features functional
- 🟡 **Needs Review**: Error handling, testing coverage
- 🔴 **Before Production**: Security audit, comprehensive testing

See [PROJECT_ANALYSIS_STRENGTHS_WEAKNESSES.md](PROJECT_ANALYSIS_STRENGTHS_WEAKNESSES.md) for detailed analysis.

---

## 👥 Contributing

1. Create a feature branch: `git checkout -b feature/your-feature`
2. Commit changes: `git commit -m "Add feature description"`
3. Push to branch: `git push origin feature/your-feature`
4. Submit a pull request

---

## 📝 License

This project is managed by Pusat Khidmat Lubok Antu. For licensing inquiries, contact the project administrator.

---

## 📞 Support

For issues or questions:
- Check documentation files in repository
- Review the [Project Analysis](PROJECT_ANALYSIS_STRENGTHS_WEAKNESSES.md)
- Submit issues with detailed reproduction steps
- Contact the development team

---

**Last Updated**: January 5, 2026  
**Backend Status**: Separated to standalone repository  
**Frontend Focus**: Flutter mobile + Firebase integration
