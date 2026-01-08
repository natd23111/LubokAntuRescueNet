import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:convert';
import 'l10n/app_localizations.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/citizen_dashboard.dart';
import 'screens/citizen/view_reports_screen.dart';
import 'screens/citizen/view_aid_program_screen.dart';
import 'screens/citizen/view_aid_request_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/firebase_test_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/aid_program_provider.dart';
import 'providers/reports_provider.dart';
import 'providers/aid_request_provider.dart';
import 'providers/weather_provider.dart';
import 'providers/warnings_provider.dart';
import 'providers/notifications_provider.dart';
import 'services/navigation_service.dart';
import 'services/push_notification_service.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'providers/locale_provider.dart';

// navigationKey provided by services/navigation_service.dart

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Register background message handler at startup
  // This allows notifications to be received even when app is closed
  print('🔔 Registering background message handler...');
  await PushNotificationService.registerBackgroundHandler();
  print('✅ Background message handler registered');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AidProgramProvider()),
        ChangeNotifierProvider(create: (_) => WeatherProvider()),
        ChangeNotifierProvider(create: (_) => WarningsProvider()),
        ChangeNotifierProvider(create: (_) => NotificationsProvider()),
        ChangeNotifierProxyProvider<AuthProvider, ReportsProvider>(
          create: (context) => ReportsProvider(
            authProvider: Provider.of<AuthProvider>(context, listen: false),
          ),
          update: (context, authProvider, previous) =>
              ReportsProvider(authProvider: authProvider),
        ),
        ChangeNotifierProxyProvider<AuthProvider, AidRequestProvider>(
          create: (context) => AidRequestProvider(
            authProvider: Provider.of<AuthProvider>(context, listen: false),
          ),
          update: (context, authProvider, previous) =>
              AidRequestProvider(authProvider: authProvider),
        ),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);    final notificationsProvider = Provider.of<NotificationsProvider>(context, listen: false);
    
    // Set up the global notification tap handler
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupGlobalNotificationHandler(notificationsProvider, context);
    });
        return MaterialApp(
      title: 'Lubok Antu RescueNet',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      locale: localeProvider.locale,
      navigatorKey: navigationKey,
      home: SplashScreen(),
      supportedLocales: const [
        Locale('en'),
        Locale('ms'),
      ],
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routes: {
        '/splash': (_) => SplashScreen(),
        '/login': (_) => LoginScreen(),
        '/register': (_) => RegisterScreen(),
        '/home': (_) => HomeRouter(),
        '/view-reports': (_) => ViewReportsScreen(),
        '/view-public-reports': (_) => ViewReportsScreen(),
        '/view-aid-programs': (_) => ViewAidProgramScreen(),
        '/view-aid-requests': (_) => ViewAidRequestScreen(),
        '/program-details': (_) => ViewAidProgramScreen(),
        '/weather-alerts': (_) => HomeRouter(), // Fallback to home
        '/firebase-test': (_) => FirebaseTestScreen(),
      },
      onGenerateRoute: (settings) {
        // Handle route generation with arguments
        final args = settings.arguments as Map<String, dynamic>?;

        switch (settings.name) {
          case '/view-reports':
          case '/view-public-reports':
            return MaterialPageRoute(
              builder: (_) => ViewReportsScreen(),
              settings: RouteSettings(arguments: args),
            );
          case '/program-details':
          case '/view-aid-programs':
            return MaterialPageRoute(
              builder: (_) => ViewAidProgramScreen(),
              settings: RouteSettings(arguments: args),
            );
          default:
            return null;
        }
      },
    );
  }
  static void _setupGlobalNotificationHandler(NotificationsProvider notificationsProvider, BuildContext context) {
    // This sets up the callback that handles notification taps throughout the app lifecycle
    notificationsProvider.onNotificationTapped = (String notificationId) {
      print('🔔 Global notification tap handler: $notificationId');
      // Parse notification ID to extract reportId/requestId and type
      try {
        final Map<String, dynamic>? payloadMap = jsonDecode(notificationId) as Map<String, dynamic>?;
        if (payloadMap != null) {
          final reportId = payloadMap['reportId'] ?? payloadMap['report_id'];
          final requestId = payloadMap['requestId'] ?? payloadMap['request_id'];
          final reportType = payloadMap['reportType'] ?? payloadMap['report_type'] ?? payloadMap['type'];
          
          if (requestId != null) {
            navigationKey.currentState?.pushNamed(
              '/view-aid-requests',
              arguments: {'requestId': requestId},
            );
          } else if (reportId != null && reportType != null) {
            navigationKey.currentState?.pushNamed(
              '/view-reports',
              arguments: {'reportType': reportType, 'reportId': reportId},
            );
          }
        }
      } catch (e) {
        print('⚠️ Could not parse notification payload: $e');
      }
    };
  }}

class HomeRouter extends StatelessWidget {
  const HomeRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.userRole == 'admin') {
          return AdminDashboardScreen();
        }
        // Default to citizen dashboard for all other roles
        return HomeScreen();
      },
    );
  }
}
