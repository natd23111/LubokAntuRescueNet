import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../home_screen.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _icController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _agree = false;

  @override
  void dispose() {
    _nameController.dispose();
    _icController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Please enter your email';
    final pattern = RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]+");
    if (!pattern.hasMatch(v.trim())) return 'Enter a valid email';
    return null;
  }

  Future<void> _submit(AuthProvider auth) async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agree) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('You must agree to the Terms & Conditions')));
      return;
    }

    final data = {
      'name': _nameController.text.trim(),
      'ic_number': _icController.text.trim(),
      'email': _emailController.text.trim(),
      'password': _passwordController.text,
      'role': 'citizen',
    };

    final success = await auth.register(data);
    if (success) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Registration failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final primaryGreen = Color(0xFF0E9D63);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryGreen,
        title: Text('Register'),
        leading: BackButton(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Create a new citizen account', style: TextStyle(color: Colors.black54)),
              SizedBox(height: 12),

              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 2,
                child: Padding(
                  padding: EdgeInsets.all(14),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Full name
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(labelText: 'Full Name', hintText: 'Enter full name', border: OutlineInputBorder()),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your full name' : null,
                        ),
                        SizedBox(height: 12),

                        // IC Number
                        TextFormField(
                          controller: _icController,
                          decoration: InputDecoration(labelText: 'IC Number', hintText: 'e.g., 950123-14-5678', border: OutlineInputBorder()),
                          keyboardType: TextInputType.text,
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your IC number' : null,
                        ),
                        SizedBox(height: 12),

                        // Email
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(labelText: 'Email', hintText: 'Enter email address', border: OutlineInputBorder()),
                          keyboardType: TextInputType.emailAddress,
                          validator: _validateEmail,
                        ),
                        SizedBox(height: 12),

                        // Password
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(labelText: 'Password', hintText: 'Enter password', border: OutlineInputBorder()),
                          obscureText: true,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Please enter a password';
                            if (v.length < 8) return 'Minimum 8 characters';
                            return null;
                          },
                        ),
                        SizedBox(height: 6),
                        Text('Minimum 8 characters', style: TextStyle(fontSize: 12, color: Colors.black45)),
                        SizedBox(height: 12),

                        // Confirm password
                        TextFormField(
                          controller: _confirmController,
                          decoration: InputDecoration(labelText: 'Confirm Password', hintText: 'Re-enter password', border: OutlineInputBorder()),
                          obscureText: true,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Please confirm your password';
                            if (v != _passwordController.text) return 'Passwords do not match';
                            return null;
                          },
                        ),

                        SizedBox(height: 12),

                        // Terms checkbox
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Checkbox(value: _agree, onChanged: (v) => setState(() => _agree = v ?? false)),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _agree = !_agree),
                                child: Text('I agree to the Terms & Conditions and Privacy Policy *', style: TextStyle(height: 1.3)),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 12),

                        SizedBox(
                          height: 44,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: primaryGreen, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                            onPressed: auth.isLoading ? null : () => _submit(auth),
                            child: auth.isLoading ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text('Submit'),
                          ),
                        ),

                        SizedBox(height: 8),

                        SizedBox(
                          height: 44,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                            onPressed: () => Navigator.pop(context),
                            child: Text('Cancel'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
