import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
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
            content: Text('This email is not authorized as admin'),
            backgroundColor: Colors.red,
          ),
        );
        await authProvider.logout();
        return;
      }
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Sign in failed: ${authProvider.errorMessage ?? 'Unknown error'}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final primaryGreen = Color(0xFF0E9D63);

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
                      'Emergency and Community Aid Reporting System',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            // Form card
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Sign In',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
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
                                            : Colors.grey.shade300),
                                  ),
                                  onPressed: () =>
                                      setState(() => _isCitizen = true),
                                  child: Text('Citizen',
                                      style: TextStyle(
                                          color: _isCitizen
                                              ? primaryGreen
                                              : Colors.black54)),
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
                                            : Colors.grey.shade300),
                                  ),
                                  onPressed: () =>
                                      setState(() => _isCitizen = false),
                                  child: Text('Admin',
                                      style: TextStyle(
                                          color: !_isCitizen
                                              ? primaryGreen
                                              : Colors.black54)),
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
                              labelText: 'Email',
                              hintText: 'Enter your email',
                              prefixIcon: Icon(Icons.email_outlined),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Please enter your Email'
                                : null,
                          ),
                          const SizedBox(height: 12),

                          // Password field with icon & show/hide
                          TextFormField(
                            controller: _passwordController,
                            obscureText: !_showPassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              hintText: 'Enter your password',
                              prefixIcon: Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _showPassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () =>
                                    setState(() => _showPassword = !_showPassword),
                              ),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            validator: (v) => (v == null || v.isEmpty)
                                ? 'Please enter your password'
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
                                  : const Text('Sign In'),
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
                    const Text("Don't have an account? ",
                        style: TextStyle(color: Colors.black54)),
                    TextButton(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => RegisterScreen())),
                      style: TextButton.styleFrom(foregroundColor: primaryGreen),
                      child: const Text('Register here'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
