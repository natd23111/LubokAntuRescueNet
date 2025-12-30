import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart' as auth_provider;

class FirebaseTestScreen extends StatefulWidget {
  @override
  State<FirebaseTestScreen> createState() => _FirebaseTestScreenState();
}

class _FirebaseTestScreenState extends State<FirebaseTestScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Firebase Test'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Connection Status
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                border: Border.all(color: Colors.green),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '✅ Firebase Connected',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Project: lubok-antu-rescuenet',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // Test Sign Up
            Text(
              'Test Sign Up',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Full Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                hintText: 'Email (test@example.com)',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Password (6+ chars)',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _testSignUp(context),
              icon: Icon(Icons.person_add),
              label: Text('Sign Up'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 50),
              ),
            ),
            SizedBox(height: 20),

            // Test Sign In
            Text(
              'Test Sign In',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _testSignIn(context),
              icon: Icon(Icons.login),
              label: Text('Sign In'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 50),
              ),
            ),
            SizedBox(height: 20),

            // Current User Info
            Text(
              'Current User',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Consumer<auth_provider.AuthProvider>(
              builder: (context, authProvider, _) {
                if (authProvider.isAuthenticated) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoRow('Name:', authProvider.userName ?? 'N/A'),
                            _buildInfoRow('Email:', authProvider.userEmail ?? 'N/A'),
                            _buildInfoRow('Role:', authProvider.userRole ?? 'N/A'),
                            _buildInfoRow('Status:', authProvider.accountStatus ?? 'N/A'),
                          ],
                        ),
                      ),
                      SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () => _testSignOut(context),
                        icon: Icon(Icons.logout),
                        label: Text('Sign Out'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                          foregroundColor: Colors.white,
                          minimumSize: Size(double.infinity, 50),
                        ),
                      ),
                    ],
                  );
                } else {
                  return Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text('No user logged in'),
                  );
                }
              },
            ),
            SizedBox(height: 20),

            // Test Database Write
            Text(
              'Test Firestore Write',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _testFirestoreWrite,
              icon: Icon(Icons.save),
              label: Text('Create Test Data in Firestore'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade700,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 50),
              ),
            ),
            SizedBox(height: 20),

            // Test Database Read
            Text(
              'Test Firestore Read',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _testFirestoreRead,
              icon: Icon(Icons.cloud_download),
              label: Text('Read Test Data from Firestore'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple.shade700,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _testSignUp(BuildContext context) async {
    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _nameController.text.isEmpty) {
      _showMessage('Please fill all fields', Colors.red);
      return;
    }

    final authProvider = Provider.of<auth_provider.AuthProvider>(context, listen: false);
    final success = await authProvider.register({
      'email': _emailController.text,
      'password': _passwordController.text,
      'full_name': _nameController.text,
      'role': 'citizen',
    });

    if (success) {
      _showMessage('✅ Sign up successful!', Colors.green);
      _emailController.clear();
      _passwordController.clear();
      _nameController.clear();
    } else {
      _showMessage('❌ Sign up failed: ${authProvider.errorMessage}', Colors.red);
    }
  }

  Future<void> _testSignIn(BuildContext context) async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showMessage('Please enter email and password', Colors.red);
      return;
    }

    final authProvider = Provider.of<auth_provider.AuthProvider>(context, listen: false);
    final success = await authProvider.login(
      _emailController.text,
      _passwordController.text,
    );

    if (success) {
      _showMessage('✅ Sign in successful!', Colors.green);
    } else {
      _showMessage('❌ Sign in failed: ${authProvider.errorMessage}', Colors.red);
    }
  }

  Future<void> _testSignOut(BuildContext context) async {
    final authProvider = Provider.of<auth_provider.AuthProvider>(context, listen: false);
    await authProvider.logout();
    _showMessage('✅ Signed out', Colors.green);
  }

  Future<void> _testFirestoreWrite() async {
    try {
      await _firestore.collection('test_data').add({
        'message': 'This is a test message from Flutter',
        'timestamp': DateTime.now().toIso8601String(),
        'platform': 'web',
      });
      _showMessage('✅ Data written to Firestore!', Colors.green);
    } catch (e) {
      _showMessage('❌ Error writing to Firestore: $e', Colors.red);
    }
  }

  Future<void> _testFirestoreRead() async {
    try {
      final snapshot = await _firestore.collection('test_data').limit(5).get();
      final count = snapshot.docs.length;
      _showMessage('✅ Read $count documents from Firestore!', Colors.green);
    } catch (e) {
      _showMessage('❌ Error reading from Firestore: $e', Colors.red);
    }
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: Duration(seconds: 3),
      ),
    );
  }
}
