import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../constants/api_constants.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
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
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Initialize controllers with user data from AuthProvider
    _fullNameController = TextEditingController(text: authProvider.userName ?? '');
    _icController = TextEditingController(text: authProvider.userIc ?? '');
    _emailController = TextEditingController(text: authProvider.userEmail ?? '');
    _phoneController = TextEditingController(text: authProvider.userPhone ?? '');
    _addressController = TextEditingController(text: authProvider.userAddress ?? '');
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

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final api = ApiService();

    try {
      final response = await api.put(ApiConstants.userProfile, {
        'email': _emailController.text.trim(),
        'phone_no': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
      });

      print('Profile update response: ${response.statusCode}');
      print('Response data: ${response.data}');

      if (response.data['success']) {
        // Update AuthProvider with new data
        authProvider.userEmail = _emailController.text.trim();
        authProvider.userPhone = _phoneController.text.trim();
        authProvider.userAddress = _addressController.text.trim();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile updated successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.data['message'] ?? 'Error updating profile')),
        );
      }
    } catch (e) {
      print('Profile update error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $e')),
      );
    }
  }

  Future<void> _changePassword() async {
    if (_currentPasswordController.text.isEmpty ||
        _newPasswordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('All password fields are required')),
      );
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('New passwords do not match')),
      );
      return;
    }

    if (_newPasswordController.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('New password must be at least 8 characters')),
      );
      return;
    }

    final api = ApiService();

    try {
      final response = await api.post(ApiConstants.changePassword, {
        'current_password': _currentPasswordController.text,
        'new_password': _newPasswordController.text,
        'new_password_confirmation': _confirmPasswordController.text,
      });

      if (response.data['success']) {
        // Clear password fields
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Password changed successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.data['message'] ?? 'Error changing password')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error changing password: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryGreen = Color(0xFF0E9D63);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header
          Container(
            color: primaryGreen,
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('RescueNet', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('User Profile', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Scrollable content
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(16),
              children: [
                // Profile Avatar Section
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    // Generate initials from full name
                    String initials = 'U';
                    if (authProvider.userName != null && authProvider.userName!.isNotEmpty) {
                      final names = authProvider.userName!.split(' ');
                      initials = names.map((name) => name.isNotEmpty ? name[0].toUpperCase() : '').join();
                      if (initials.isEmpty) initials = 'U';
                    }
                    
                    return Center(
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: primaryGreen.withOpacity(0.2),
                            child: Text(initials, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: primaryGreen)),
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
                      Text('Full Name', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: _fullNameController,
                        enabled: false,
                        decoration: InputDecoration(
                          hintText: 'Full Name',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          fillColor: Colors.grey.shade100,
                          filled: true,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text('Name cannot be changed', style: TextStyle(color: Colors.grey, fontSize: 12)),

                      SizedBox(height: 16),

                      // IC Number
                      Text('IC Number', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: _icController,
                        enabled: false,
                        decoration: InputDecoration(
                          hintText: 'IC Number',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          fillColor: Colors.grey.shade100,
                          filled: true,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text('IC number cannot be changed', style: TextStyle(color: Colors.grey, fontSize: 12)),

                      SizedBox(height: 16),

                      // Email
                      Text('Email *', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: 'Enter email',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        validator: (value) {
                          if (value?.isEmpty ?? true) return 'Email is required';
                          if (!value!.contains('@')) return 'Please enter a valid email';
                          return null;
                        },
                      ),

                      SizedBox(height: 16),

                      // Phone Number
                      Text('Phone Number *', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          hintText: 'Enter phone number',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        validator: (value) {
                          if (value?.isEmpty ?? true) return 'Phone number is required';
                          return null;
                        },
                      ),

                      SizedBox(height: 16),

                      // Address
                      Text('Address', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: _addressController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Enter your address',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),

                      SizedBox(height: 24),

                      // Change Password Section
                      Divider(),
                      SizedBox(height: 16),
                      Text('Change Password', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.black87)),

                      SizedBox(height: 16),

                      // Current Password
                      Text('Current Password', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: _currentPasswordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: 'Enter current password',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),

                      SizedBox(height: 16),

                      // New Password
                      Text('New Password', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: _newPasswordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: 'Enter new password',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        validator: (value) {
                          if (value != null && value.isNotEmpty && value.length < 8) {
                            return 'Password must be at least 8 characters';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 6),
                      Text('Minimum 8 characters', style: TextStyle(color: Colors.grey, fontSize: 12)),

                      SizedBox(height: 16),

                      // Confirm New Password
                      Text('Confirm New Password', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: 'Re-enter new password',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        validator: (value) {
                          if (_newPasswordController.text.isNotEmpty && value != _newPasswordController.text) {
                            return 'Passwords do not match';
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Center(
                          child: Text('Change Password', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                        ),
                      ),

                      SizedBox(height: 24),

                      // Account Information Section
                      Consumer<AuthProvider>(
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
                                Text('Account Information', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
                                SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Member since:', style: TextStyle(color: Colors.black54)),
                                    Text(authProvider.memberSince ?? 'Loading...', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.black87)),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Account Status:', style: TextStyle(color: Colors.black54)),
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(authProvider.accountStatus ?? 'Loading...', style: TextStyle(color: Colors.green.shade700, fontSize: 12, fontWeight: FontWeight.w600)),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('User ID:', style: TextStyle(color: Colors.black54)),
                                    Text(authProvider.userId ?? 'Loading...', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.black87)),
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Center(
                          child: Text('Update Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                        ),
                      ),

                      SizedBox(height: 12),

                      // Cancel Button
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Center(
                          child: Text('Cancel', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 16)),
                        ),
                      ),

                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
