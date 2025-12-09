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
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _addressLine3Controller = TextEditingController();
  final _addressCityController = TextEditingController();
  final _addressPostcodeController = TextEditingController();
  final _addressStateController = TextEditingController();
  bool _agree = false;
  bool _hidePassword = true;
  bool _hideConfirm = true;

  @override
  void dispose() {
    _nameController.dispose();
    _icController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _phoneController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _addressLine3Controller.dispose();
    _addressCityController.dispose();
    _addressPostcodeController.dispose();
    _addressStateController.dispose();
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('You must agree to the Terms & Conditions')));
      return;
    }

    final data = {
      'full_name': _nameController.text.trim(),
      'ic_no': _icController.text.trim(),
      'email': _emailController.text.trim(),
      'phone_no': _phoneController.text.trim(),
      'address_line_1': _addressLine1Controller.text.trim(),
      'address_line_2': _addressLine2Controller.text.trim(),
      'address_line_3': _addressLine3Controller.text.trim(),
      'address_city': _addressCityController.text.trim(),
      'address_postcode': _addressPostcodeController.text.trim(),
      'address_state': _addressStateController.text.trim(),
      'password': _passwordController.text,
      'password_confirmation': _confirmController.text,
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
                          maxLength: 40,
                          decoration: InputDecoration(labelText: 'Full Name', hintText: 'Enter full name', border: OutlineInputBorder(), counterText: '',),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your full name' : null,
                        ),
                        SizedBox(height: 12),

                        // IC Number
                        TextFormField(
                          controller: _icController,
                          maxLength: 14,
                          decoration: InputDecoration(labelText: 'IC Number', hintText: 'e.g., 950123-13-5678', border: OutlineInputBorder(), counterText: '',),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            final formatted = _formatIC(value);
                            if (formatted != value) {
                              _icController.value = _icController.value.copyWith(
                                text: formatted,
                                selection: TextSelection.collapsed(offset: formatted.length),
                              );
                            }
                          },
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your IC number' : null,
                        ),
                        SizedBox(height: 12),

                        // Phone
                        TextFormField(
                          controller: _phoneController,
                          maxLength: 12,
                          decoration: InputDecoration(labelText: 'Phone No', hintText: 'Enter Phone No', border: OutlineInputBorder(), counterText: '',),
                          keyboardType: TextInputType.phone,
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your phone number' : null,
                        ),
                        SizedBox(height: 12),

                        // Address Line 1
                        TextFormField(
                          controller: _addressLine1Controller,
                          maxLength: 30,
                          decoration: InputDecoration(labelText: 'Address Line 1', border: OutlineInputBorder(), counterText: '',),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter address line 1' : null,
                        ),
                        SizedBox(height: 12),

                        // Address Line 2
                        TextFormField(
                          controller: _addressLine2Controller,
                          maxLength: 30,
                          decoration: InputDecoration(labelText: 'Address Line 2', border: OutlineInputBorder(), counterText: '',),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter address line 2' : null,
                        ),
                        SizedBox(height: 12),

                        // Address Line 3
                        TextFormField(
                          controller: _addressLine3Controller,
                          maxLength: 30,
                          decoration: InputDecoration(labelText: 'Address Line 3', border: OutlineInputBorder(), counterText: '',),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter address line 3' : null,
                        ),
                        SizedBox(height: 12),

                        // City
                        TextFormField(
                          controller: _addressCityController,
                          maxLength: 15,
                          decoration: InputDecoration(labelText: 'City', border: OutlineInputBorder(), counterText: '',),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter city' : null,
                        ),
                        SizedBox(height: 12),

                        // Postcode
                        TextFormField(
                          controller: _addressPostcodeController,
                          maxLength: 7,
                          decoration: InputDecoration(labelText: 'Postcode', border: OutlineInputBorder(), counterText: '',),
                          keyboardType: TextInputType.number,
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter postcode' : null,
                        ),
                        SizedBox(height: 12),

                        // State
                        TextFormField(
                          controller: _addressStateController,
                          maxLength: 20,
                          decoration: InputDecoration(labelText: 'State', border: OutlineInputBorder(), counterText: '',),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter state' : null,
                        ),
                        SizedBox(height: 12),

                        // Email
                        TextFormField(
                          controller: _emailController,
                          maxLength: 64,
                          decoration: InputDecoration(labelText: 'Email', hintText: 'Enter email address', border: OutlineInputBorder(), counterText: '',),
                          keyboardType: TextInputType.emailAddress,
                          validator: _validateEmail,
                        ),
                        SizedBox(height: 12),

                        // Password
                        TextFormField(
                          controller: _passwordController,
                          maxLength: 20,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            hintText: 'Enter password',
                            border: OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(_hidePassword ? Icons.visibility_off : Icons.visibility),
                              onPressed: () => setState(() => _hidePassword = !_hidePassword),
                            ), counterText: '',
                          ),
                          obscureText: _hidePassword,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Please enter a password';
                            if (v.length < 8) return 'Minimum 8 characters';
                            if (v.length > 20) return 'Maximum 20 characters';
                            return null;
                          },
                        ),
                        SizedBox(height: 6),
                        Text('Minimum 8 characters', style: TextStyle(fontSize: 12, color: Colors.black45)),
                        SizedBox(height: 12),

                        // Confirm password
                        TextFormField(
                          controller: _confirmController,
                          decoration: InputDecoration(
                            labelText: 'Confirm Password',
                            hintText: 'Re-enter password',
                            border: OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(_hideConfirm ? Icons.visibility_off : Icons.visibility),
                              onPressed: () => setState(() => _hideConfirm = !_hideConfirm),
                            ),
                          ),
                          obscureText: _hideConfirm,
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
