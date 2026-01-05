import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../services/push_notification_service.dart';
import '../../services/location_service.dart';
import 'register_screen.dart';
import '../../widgets/app_footer.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isCitizen = true;
  bool _showPassword = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit(AuthProvider authProvider) async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final l10n = AppLocalizations.of(context)!;

    const List<String> adminEmails = [
      'admin@rescuenet.com',
      'admin123@example.com',
    ];

    bool isAdminEmail = adminEmails.contains(email.toLowerCase());

    final success = await authProvider.login(email, password);
    if (success) {
      if (!_isCitizen && !isAdminEmail) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.adminNotAuthorized),
            backgroundColor: Colors.red,
          ),
        );
        await authProvider.logout();
        return;
      }

      // Request permissions after successful login
      await _requestPermissions();

      Navigator.pushReplacementNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${l10n.signInFailed}: ${authProvider.errorMessage ?? l10n.unknownError}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Request notifications and location permissions
  Future<void> _requestPermissions() async {
    try {
      print('📱 Requesting permissions after login...');

      // Initialize push notifications
      await PushNotificationService.initializePushNotifications();
      print('✅ Push notifications initialized');

      // Request location permission
      await LocationService.requestLocationPermission();
      print('✅ Location permission requested');
    } catch (e) {
      print('⚠️ Permission request error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final primaryGreen = Color(0xFF0E9D63);
    final l10n = AppLocalizations.of(context)!;

    // Set status bar color to match header
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: primaryGreen,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top section with bigger logo - extend behind status bar
            SafeArea(
              top: false,
              bottom: false,
              child: Container(
                width: double.infinity,
                color: primaryGreen,
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 15,
                  bottom: 15,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Language toggle button at top
                    Padding(
                      padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Tooltip(
                            message: l10n.language,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => Provider.of<LocaleProvider>(
                                  context,
                                  listen: false,
                                ).toggleLanguage(),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    Localizations.localeOf(context).languageCode ==
                                            'en'
                                        ? 'EN'
                                        : 'MS',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Bigger logo
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 12,
                            offset: Offset(0, 5),
                          ),
                        ],
                        image: const DecorationImage(
                          image: AssetImage('assets/logo.png'),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      'Lubok Antu RescueNet',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.appDescription,
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            // Form card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.signIn,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Role toggle
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: _isCitizen
                                      ? primaryGreen.withOpacity(0.08)
                                      : Colors.transparent,
                                  side: BorderSide(
                                    color: _isCitizen
                                        ? primaryGreen
                                        : Colors.grey.shade300,
                                  ),
                                ),
                                onPressed: () =>
                                    setState(() => _isCitizen = true),
                                child: Text(
                                  l10n.citizen,
                                  style: TextStyle(
                                    color: _isCitizen
                                        ? primaryGreen
                                        : Colors.black54,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: !_isCitizen
                                      ? primaryGreen.withOpacity(0.08)
                                      : Colors.transparent,
                                  side: BorderSide(
                                    color: !_isCitizen
                                        ? primaryGreen
                                        : Colors.grey.shade300,
                                  ),
                                ),
                                onPressed: () =>
                                    setState(() => _isCitizen = false),
                                child: Text(
                                  l10n.admin,
                                  style: TextStyle(
                                    color: !_isCitizen
                                        ? primaryGreen
                                        : Colors.black54,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Email field with icon
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: l10n.email,
                            hintText: l10n.enterEmail,
                            prefixIcon: Icon(Icons.email_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            isDense: false,
                            contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? l10n.emailRequired
                              : null,
                        ),
                        const SizedBox(height: 12),

                        // Password field with icon & show/hide
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_showPassword,
                          decoration: InputDecoration(
                            labelText: l10n.password,
                            hintText: l10n.enterPassword,
                            prefixIcon: Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _showPassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () => setState(
                                () => _showPassword = !_showPassword,
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            isDense: false,
                            contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                          ),
                          validator: (v) => (v == null || v.isEmpty)
                              ? l10n.passwordRequired
                              : null,
                        ),
                        const SizedBox(height: 18),

                        // Sign In button
                        SizedBox(
                          height: 44,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryGreen,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: authProvider.isLoading
                                ? null
                                : () => _submit(authProvider),
                            child: authProvider.isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(l10n.signIn),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${l10n.dontHaveAccount} ',
                      style: TextStyle(color: Colors.black54),
                    ),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => RegisterScreen()),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: primaryGreen,
                      ),
                      child: Text(
                        l10n.registerHere,
                        style: TextStyle(
                          decoration: TextDecoration.underline,
                          color: primaryGreen,
                          decorationColor: primaryGreen,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const AppFooter(),
          ],
        ),
      ),
    );
  }
}
