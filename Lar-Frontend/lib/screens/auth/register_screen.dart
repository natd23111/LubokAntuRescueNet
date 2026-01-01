import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../citizen_dashboard.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _icController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _agree = false;
  bool _hidePassword = true;
  bool _hideConfirm = true;

  @override
  void dispose() {
    _nameController.dispose();
    _icController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Please enter your email';
    if (v.length > 64) return 'Email max is 64 characters';
    final pattern = RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]+");
    if (!pattern.hasMatch(v.trim())) return 'Enter a valid email';
    return null;
  }

  String _formatIC(String value) {
    value = value.replaceAll('-', '');
    if (value.length >= 6) {
      value = value.substring(0, 6) + '-' + value.substring(6);
    }
    if (value.length >= 10) {
      value = value.substring(0, 9) + '-' + value.substring(9);
    }
    return value;
  }

  Future<void> _submit(AuthProvider auth) async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agree) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must agree to the Terms & Conditions')));
      return;
    }

    final data = {
      'full_name': _nameController.text.trim(),
      'ic_no': _icController.text.trim(),
      'email': _emailController.text.trim(),
      'phone_no': _phoneController.text.trim(),
      'password': _passwordController.text,
      'password_confirmation': _confirmController.text,
    };

    final success = await auth.register(data);
    if (success) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => HomeScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final primaryGreen = const Color(0xFF0E9D63);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryGreen,
        title: const Text('Register', style: TextStyle(color: Colors.white)),
        leading: const BackButton(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Create a new citizen account',
                  style: TextStyle(color: Colors.black54)),
              const SizedBox(height: 12),

              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Full name
                        TextFormField(
                          controller: _nameController,
                          maxLength: 40,
                          decoration: InputDecoration(
                            labelText: 'Full Name',
                            hintText: 'Enter full name',
                            border: const OutlineInputBorder(),
                            counterText: '',
                            prefixIcon: const Icon(Icons.person_outline),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Please enter your full name'
                              : null,
                        ),
                        const SizedBox(height: 12),

                        // IC Number
                        TextFormField(
                          controller: _icController,
                          maxLength: 14,
                          decoration: InputDecoration(
                            labelText: 'IC Number',
                            hintText: 'e.g., 950123-13-5678',
                            border: const OutlineInputBorder(),
                            counterText: '',
                            prefixIcon: const Icon(Icons.credit_card_outlined),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            final formatted = _formatIC(value);
                            if (formatted != value) {
                              _icController.value = _icController.value.copyWith(
                                text: formatted,
                                selection: TextSelection.collapsed(
                                    offset: formatted.length),
                              );
                            }
                          },
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Please enter your IC number'
                              : null,
                        ),
                        const SizedBox(height: 12),

                        // Phone
                        TextFormField(
                          controller: _phoneController,
                          maxLength: 12,
                          decoration: InputDecoration(
                            labelText: 'Phone No',
                            hintText: 'Enter Phone No',
                            border: const OutlineInputBorder(),
                            counterText: '',
                            prefixIcon: const Icon(Icons.phone_outlined),
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Please enter your phone number'
                              : null,
                        ),
                        const SizedBox(height: 12),

                        // Email
                        TextFormField(
                          controller: _emailController,
                          maxLength: 64,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            hintText: 'Enter email address',
                            border: const OutlineInputBorder(),
                            counterText: '',
                            prefixIcon: const Icon(Icons.email_outlined),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: _validateEmail,
                        ),
                        const SizedBox(height: 12),

                        // Password
                        TextFormField(
                          controller: _passwordController,
                          maxLength: 20,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            hintText: 'Enter password',
                            border: const OutlineInputBorder(),
                            counterText: '',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(_hidePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                              onPressed: () =>
                                  setState(() => _hidePassword = !_hidePassword),
                            ),
                          ),
                          obscureText: _hidePassword,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Please enter a password';
                            if (v.length < 8) return 'Minimum 8 characters';
                            if (v.length > 20) return 'Maximum 20 characters';
                            return null;
                          },
                        ),
                        const SizedBox(height: 6),
                        const Text('Minimum 8 characters',
                            style: TextStyle(fontSize: 12, color: Colors.black45)),
                        const SizedBox(height: 12),

                        // Confirm password
                        TextFormField(
                          controller: _confirmController,
                          decoration: InputDecoration(
                            labelText: 'Confirm Password',
                            hintText: 'Re-enter password',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(_hideConfirm
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                              onPressed: () =>
                                  setState(() => _hideConfirm = !_hideConfirm),
                            ),
                          ),
                          obscureText: _hideConfirm,
                          validator: (v) {
                            if (v == null || v.isEmpty)
                              return 'Please confirm your password';
                            if (v != _passwordController.text)
                              return 'Passwords do not match';
                            return null;
                          },
                        ),

                        const SizedBox(height: 12),

                        // Terms checkbox
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Checkbox(
                                value: _agree,
                                onChanged: (v) =>
                                    setState(() => _agree = v ?? false)),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _agree = !_agree),
                                child: const Text(
                                  'I agree to the Terms & Conditions and Privacy Policy *',
                                  style: TextStyle(height: 1.3),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        SizedBox(
                          height: 44,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: primaryGreen,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8))),
                            onPressed:
                            auth.isLoading ? null : () => _submit(auth),
                            child: auth.isLoading
                                ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                                : const Text('Submit'),
                          ),
                        ),

                        const SizedBox(height: 8),

                        SizedBox(
                          height: 44,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8))),
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
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

