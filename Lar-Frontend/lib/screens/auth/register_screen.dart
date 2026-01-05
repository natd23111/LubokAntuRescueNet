import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../citizen_dashboard.dart';
import '../../widgets/app_footer.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

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

  String? _validateEmail(String? v, AppLocalizations l10n) {
    if (v == null || v.trim().isEmpty) return l10n.emailRequired;
    if (v.length > 64) return l10n.emailMaxCharacters;
    final pattern = RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]+");
    if (!pattern.hasMatch(v.trim())) return l10n.enterValidEmail;
    return null;
  }

  String _formatIC(String value) {
    value = value.replaceAll('-', '');
    if (value.length >= 6) {
      value = '${value.substring(0, 6)}-${value.substring(6)}';
    }
    if (value.length >= 10) {
      value = '${value.substring(0, 9)}-${value.substring(9)}';
    }
    return value;
  }

  Future<void> _submit(AuthProvider auth) async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agree) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.iAgreeToTerms),
        ),
      );
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
        context,
        MaterialPageRoute(builder: (_) => HomeScreen()),
      );
    } else {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.registrationFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final primaryGreen = const Color(0xFF0E9D63);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryGreen,
        title: Text(l10n.register, style: TextStyle(color: Colors.white)),
        leading: BackButton(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.createNewAccount,
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 12),

              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
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
                            labelText: l10n.fullName,
                            hintText: l10n.enterFullName,
                            border: const OutlineInputBorder(),
                            counterText: '',
                            prefixIcon: const Icon(Icons.person_outline),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? l10n.fullNameRequired
                              : null,
                        ),
                        const SizedBox(height: 12),

                        // IC Number
                        TextFormField(
                          controller: _icController,
                          maxLength: 14,
                          decoration: InputDecoration(
                            labelText: l10n.icNumber,
                            hintText: l10n.enterICNumber,
                            border: const OutlineInputBorder(),
                            counterText: '',
                            prefixIcon: const Icon(Icons.credit_card_outlined),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            final formatted = _formatIC(value);
                            if (formatted != value) {
                              _icController.value = _icController.value
                                  .copyWith(
                                    text: formatted,
                                    selection: TextSelection.collapsed(
                                      offset: formatted.length,
                                    ),
                                  );
                            }
                          },
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? l10n.icRequired
                              : null,
                        ),
                        const SizedBox(height: 12),

                        // Phone
                        TextFormField(
                          controller: _phoneController,
                          maxLength: 12,
                          decoration: InputDecoration(
                            labelText: l10n.phoneNo,
                            hintText: l10n.enterPhoneNo,
                            border: const OutlineInputBorder(),
                            counterText: '',
                            prefixIcon: const Icon(Icons.phone_outlined),
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? l10n.phoneRequired
                              : null,
                        ),
                        const SizedBox(height: 12),

                        // Email
                        TextFormField(
                          controller: _emailController,
                          maxLength: 64,
                          decoration: InputDecoration(
                            labelText: l10n.email,
                            hintText: l10n.enterEmail,
                            border: const OutlineInputBorder(),
                            counterText: '',
                            prefixIcon: const Icon(Icons.email_outlined),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) => _validateEmail(v, l10n),
                        ),
                        const SizedBox(height: 12),

                        // Password
                        TextFormField(
                          controller: _passwordController,
                          maxLength: 20,
                          decoration: InputDecoration(
                            labelText: l10n.password,
                            hintText: l10n.enterPassword,
                            border: const OutlineInputBorder(),
                            counterText: '',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _hidePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () => setState(
                                () => _hidePassword = !_hidePassword,
                              ),
                            ),
                          ),
                          obscureText: _hidePassword,
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return l10n.enterPassword2;
                            }
                            if (v.length < 8) return l10n.passwordMin8;
                            if (v.length > 20) return l10n.passwordMax20;
                            return null;
                          },
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.minimumCharacters,
                          style: TextStyle(fontSize: 12, color: Colors.black45),
                        ),
                        const SizedBox(height: 12),

                        // Confirm password
                        TextFormField(
                          controller: _confirmController,
                          decoration: InputDecoration(
                            labelText: l10n.confirmPassword,
                            hintText: l10n.reEnterPassword,
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _hideConfirm
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () =>
                                  setState(() => _hideConfirm = !_hideConfirm),
                            ),
                          ),
                          obscureText: _hideConfirm,
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return l10n.confirmPassword2;
                            }
                            if (v != _passwordController.text) {
                              return l10n.passwordMismatch;
                            }
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
                                  setState(() => _agree = v ?? false),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _agree = !_agree),
                                child: Text(
                                  l10n.agreeTermsPrivacy,
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
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: auth.isLoading
                                ? null
                                : () => _submit(auth),
                            child: auth.isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(l10n.submit),
                          ),
                        ),

                        const SizedBox(height: 8),

                        SizedBox(
                          height: 44,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: Text(l10n.cancel),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const AppFooter(),
            ],
          ),
        ),
      ),
    );
  }
}
