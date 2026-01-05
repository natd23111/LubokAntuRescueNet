import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart' as auth_provider;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late TextEditingController _fullNameController;
  late TextEditingController _icController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _currentPasswordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<auth_provider.AuthProvider>(
      context,
      listen: false,
    );

    // Initialize controllers with user data from AuthProvider
    _fullNameController = TextEditingController(
      text: authProvider.userName ?? '',
    );
    _icController = TextEditingController(text: authProvider.userIc ?? '');
    _emailController = TextEditingController(
      text: authProvider.userEmail ?? '',
    );
    _phoneController = TextEditingController(
      text: authProvider.userPhone ?? '',
    );
    _addressController = TextEditingController(
      text: authProvider.userAddress ?? '',
    );
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();

    // Fetch account info
    authProvider.fetchAccountInfo();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _icController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<auth_provider.AuthProvider>(
      context,
      listen: false,
    );
    final l10n = AppLocalizations.of(context)!;

    try {
      if (_auth.currentUser == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.userNotAuthenticated)));
        return;
      }

      // Update user profile in Firestore
      await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
        'phone_no': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Update AuthProvider with new data
      authProvider.userPhone = _phoneController.text.trim();
      authProvider.userAddress = _addressController.text.trim();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.profileUpdatedSuccessfully),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Profile update error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.errorUpdatingProfile}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _changePassword() async {
    final l10n = AppLocalizations.of(context)!;
    
    if (_currentPasswordController.text.isEmpty ||
        _newPasswordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.allPasswordFieldsRequired)),
      );
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.passwordMismatch)),
      );
      return;
    }

    if (_newPasswordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.passwordTooShort),
        ),
      );
      return;
    }

    try {
      final user = _auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.userNotAuthenticated)));
        return;
      }

      // Firebase requires re-authentication to change password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _currentPasswordController.text,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(_newPasswordController.text);

      // Clear password fields
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.passwordChangedSuccessfully),
          backgroundColor: Colors.green,
        ),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage = l10n.errorChangingPassword;
      if (e.code == 'wrong-password') {
        errorMessage = l10n.currentPasswordIncorrect;
      } else if (e.code == 'weak-password') {
        errorMessage = l10n.newPasswordTooWeak;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.errorChangingPassword}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final primaryGreen = Color(0xFF0E9D63);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryGreen,
        title: Text(l10n.profile, style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // Profile Avatar Section
          Consumer<auth_provider.AuthProvider>(
            builder: (context, authProvider, child) {
              // Generate initials from full name
              String initials = 'U';
              if (authProvider.userName != null &&
                  authProvider.userName!.isNotEmpty) {
                final names = authProvider.userName!.split(' ');
                initials = names
                    .map((name) => name.isNotEmpty ? name[0].toUpperCase() : '')
                    .join();
                if (initials.isEmpty) initials = 'U';
              }

              return Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: primaryGreen.withOpacity(0.2),
                      child: Text(
                        initials,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: primaryGreen,
                        ),
                      ),
                    ),
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: primaryGreen,
                      child: Icon(Icons.person, color: Colors.white, size: 24),
                    ),
                  ],
                ),
              );
            },
          ),

          SizedBox(height: 24),

          // Form
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Full Name
                Text(
                  l10n.fullNameLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: _fullNameController,
                  enabled: false,
                  decoration: InputDecoration(
                    hintText: l10n.fullNameLabel,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    fillColor: Colors.grey.shade100,
                    filled: true,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  l10n.cantBeChanged,
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),

                SizedBox(height: 16),

                // IC Number
                Text(
                  l10n.icLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: _icController,
                  enabled: false,
                  decoration: InputDecoration(
                    hintText: l10n.icLabel,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    fillColor: Colors.grey.shade100,
                    filled: true,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  l10n.cantBeChanged,
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),

                SizedBox(height: 16),

                // Email
                Text(
                  '${l10n.emailLabel} *',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: l10n.enterEmail,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return '${l10n.emailLabel} ${l10n.emailRequired}';
                    if (!value!.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),

                SizedBox(height: 16),

                // Phone Number
                Text(
                  '${l10n.phoneLabel} *',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: 'Enter phone number',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Phone number is required';
                    }
                    return null;
                  },
                ),

                SizedBox(height: 16),

                // Address
                Text(
                  l10n.address,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: _addressController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: l10n.enterAddress,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),

                SizedBox(height: 24),

                // Change Password Section
                Divider(),
                SizedBox(height: 16),
                Text(
                  l10n.changePassword,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),

                SizedBox(height: 16),

                // Current Password
                Text(
                  l10n.currentPassword,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: _currentPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: l10n.enterCurrentPassword,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),

                SizedBox(height: 16),

                // New Password
                Text(
                  l10n.newPassword,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: l10n.enterNewPassword,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value != null && value.isNotEmpty && value.length < 8) {
                      return l10n.passwordMustBeAtLeast8;
                    }
                    return null;
                  },
                ),
                SizedBox(height: 6),
                Text(
                  l10n.minimumPasswordLength,
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),

                SizedBox(height: 16),

                // Confirm New Password
                Text(
                  l10n.confirmNewPassword,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: l10n.reEnterNewPassword,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (_newPasswordController.text.isNotEmpty &&
                        value != _newPasswordController.text) {
                      return l10n.passwordMismatch;
                    }
                    return null;
                  },
                ),

                SizedBox(height: 16),

                // Change Password Button
                ElevatedButton(
                  onPressed: _changePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      l10n.changePassword,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 24),

                // Account Information Section
                Consumer<auth_provider.AuthProvider>(
                  builder: (context, authProvider, child) {
                    return Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.accountInformation,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                l10n.memberSince,
                                style: TextStyle(color: Colors.black54),
                              ),
                              Text(
                                authProvider.memberSince ?? 'Loading...',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                l10n.accountStatus,
                                style: TextStyle(color: Colors.black54),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  authProvider.accountStatus ?? 'Loading...',
                                  style: TextStyle(
                                    color: Colors.green.shade700,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                l10n.userId,
                                style: TextStyle(color: Colors.black54),
                              ),
                              Text(
                                authProvider.userId ?? 'Loading...',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),

                SizedBox(height: 24),

                // Update Profile Button
                ElevatedButton(
                  onPressed: _updateProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      l10n.updateProfile,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 12),

                // Cancel Button
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      l10n.cancel,
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
