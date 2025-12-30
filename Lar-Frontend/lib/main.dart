import 'package:flutter/material.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/citizen_dashboard.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/firebase_test_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/aid_program_provider.dart';
import 'providers/reports_provider.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AidProgramProvider()),
        ChangeNotifierProvider(create: (_) => ReportsProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lubok Antu RescueNet',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LoginScreen(),
      routes: {
        '/login': (_) => LoginScreen(),
        '/register': (_) => RegisterScreen(),
        '/home': (_) => HomeRouter(),
        '/firebase-test': (_) => FirebaseTestScreen(),  // For testing if needed
      },
    );
  }
}

class HomeRouter extends StatelessWidget {
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
