import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseSeeder {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> seedDatabase() async {
    try {
      print('Starting Firebase database seeding...');

      // Create admin user
      print('Creating admin user...');
      final adminId = await _createUser(
        email: 'admin@rescuenet.com',
        password: 'password123',
        fullName: 'Admin User',
        icNo: '960115-12-1234',
        phoneNo: '0123456789',
        address: 'Admin Office, Lubok Antu',
        role: 'admin',
      );

      // Create citizen user
      print('Creating citizen user...');
      final citizenUserId = await _createUser(
        email: 'citizen@rescuenet.com',
        password: 'password123',
        fullName: 'John Citizen',
        icNo: '980225-08-5678',
        phoneNo: '0129876543',
        address: 'Block A, Jalan Sejahtera, Lubok Antu',
        role: 'resident',
      );

      // Only proceed if we have valid user IDs
      if (adminId == null || citizenUserId == null) {
        throw Exception('Failed to create seed users');
      }

      // Create aid programs
      print('Creating aid programs...');
      await _createAidPrograms();

      // Create reports
      print('Creating reports...');
      await _createReports(citizenUserId);

      print('✅ Firebase seeding completed successfully!');
    } catch (e) {
      print('❌ Error seeding database: $e');
      rethrow;
    }
  }

  static Future<String?> _createUser({
    required String email,
    required String password,
    required String fullName,
    required String icNo,
    required String phoneNo,
    required String address,
    required String role,
  }) async {
    try {
      // Check if user already exists in Firestore
      final existingUsers = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      
      if (existingUsers.docs.isNotEmpty) {
        print('  ℹ User already exists: $email');
        return existingUsers.docs.first.id;
      }

      // Try to create Firebase Auth user
      UserCredential? userCredential;
      try {
        userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      } catch (authError) {
        if (authError.toString().contains('email-already-in-use')) {
          // User exists in Auth, try to sign in instead
          print('  ℹ Auth user already exists: $email');
          userCredential = await _auth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
        } else {
          rethrow;
        }
      }

      // Create or update user profile in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'full_name': fullName,
        'ic_no': icNo,
        'phone_no': phoneNo,
        'address': address,
        'email': email,
        'role': role,
        'status': 'active',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      print('  ✓ Created/updated user: $email ($role)');
      return userCredential.user!.uid;
    } catch (e) {
      print('  ✗ Error creating user $email: $e');
      rethrow;
    }
    return null;
  }

  static Future<void> _createAidPrograms() async {
    final programs = [
      {
        'title': 'B40 Financial Assistance 2025',
        'description':
            'Monthly financial assistance for households in the B40 category. Program provides RM200-500 monthly aid based on household income verification.',
        'category': 'financial',
        'program_type': 'Monthly',
        'aid_amount': '350',
        'criteria':
            'Household monthly income below RM2000, Malaysian citizen with valid IC',
        'start_date': '2025-01-01',
        'end_date': '2025-12-31',
        'status': 'active',
      },
      {
        'title': 'Disaster Relief Fund',
        'description':
            'Emergency assistance for residents affected by floods, landslides, and other natural disasters. Immediate cash aid and recovery support.',
        'category': 'emergency',
        'program_type': 'One-time',
        'aid_amount': '1500',
        'criteria':
            'Must be affected by natural disaster, provide proof of residence and damage',
        'start_date': '2024-11-01',
        'end_date': '2025-12-31',
        'status': 'active',
      },
      {
        'title': 'Medical Emergency Fund',
        'description':
            'Assistance for medical emergencies and critical healthcare expenses. Covers hospitalization, emergency treatments, and essential medications.',
        'category': 'medical',
        'program_type': 'One-time',
        'aid_amount': '2000',
        'criteria':
            'Diagnosed medical emergency, income below RM4000/month, valid medical documents',
        'start_date': '2025-01-01',
        'end_date': '2025-12-31',
        'status': 'active',
      },
      {
        'title': 'Education Scholarship Program',
        'description':
            'Scholarships for underprivileged students pursuing primary, secondary, or tertiary education. Covers tuition fees and educational materials.',
        'category': 'education',
        'program_type': 'Quarterly',
        'aid_amount': '500',
        'criteria':
            'Student with household income below RM3000/month, academic records required',
        'start_date': '2025-01-15',
        'end_date': '2025-12-31',
        'status': 'active',
      },
      {
        'title': 'Housing Assistance Program',
        'description':
            'Support for housing renovation, repairs, and construction for low-income families. Includes materials and labor support.',
        'category': 'housing',
        'program_type': 'One-time',
        'aid_amount': '3000',
        'criteria':
            'Own residential land/house, household income below RM2500/month',
        'start_date': '2025-02-01',
        'end_date': '2025-12-31',
        'status': 'inactive',
      },
    ];

    for (var program in programs) {
      try {
        program['created_at'] = DateTime.now().toIso8601String();
        program['updated_at'] = DateTime.now().toIso8601String();

        await _firestore.collection('aid_programs').add(program);
        print('  ✓ Created program: ${program['title']}');
      } catch (e) {
        print('  ✗ Error creating program ${program['title']}: $e');
        rethrow;
      }
    }
  }

  static Future<void> _createReports(String? citizenUserId) async {
    final reports = [
      {
        'title': 'House Fire in Taman Sejahtera',
        'type': 'Fire',
        'location': 'Taman Sejahtera, Lubok Antu',
        'description':
            'House fire reported at Taman Sejahtera. Smoke visible from nearby houses. Fire department has been notified. Residents evacuating.',
        'status': 'unresolved',
        'priority': 'high',
        'reporter_name': 'John Doe',
        'reporter_ic': '901234-12-3456',
        'reporter_contact': '011-9876 5432',
        'date_reported':
            DateTime.now().subtract(Duration(days: 1)).toIso8601String(),
        'date_updated': null,
        'admin_notes': null,
        'user_id': citizenUserId,
      },
      {
        'title': 'Flood in Jalan Sungai Besar',
        'type': 'Flood',
        'location': 'Jalan Sungai Besar, Lubok Antu',
        'description':
            'Heavy flooding reported in residential area. Water level rising. Residents moving to higher ground. Emergency services on standby.',
        'status': 'in-progress',
        'priority': 'high',
        'reporter_name': 'Ahmad Abdullah',
        'reporter_ic': '850615-08-5678',
        'reporter_contact': '012-3456 7890',
        'date_reported':
            DateTime.now().subtract(Duration(days: 2)).toIso8601String(),
        'date_updated':
            DateTime.now().subtract(Duration(hours: 3)).toIso8601String(),
        'admin_notes': 'Emergency services deployed. Evacuation in progress.',
        'user_id': citizenUserId,
      },
      {
        'title': 'Medical Emergency in Kampung Meruan',
        'type': 'Medical Emergency',
        'location': 'Kampung Meruan, Lubok Antu',
        'description':
            'Severe allergic reaction reported. Ambulance dispatched. Patient stable.',
        'status': 'resolved',
        'priority': 'low',
        'reporter_name': 'Ahmad Abdullah',
        'reporter_ic': '850615-08-5678',
        'reporter_contact': '012-3456 7890',
        'date_reported':
            DateTime.now().subtract(Duration(days: 3)).toIso8601String(),
        'date_updated':
            DateTime.now().subtract(Duration(days: 2)).toIso8601String(),
        'admin_notes': 'Patient transported to hospital. Status: Stable.',
        'user_id': citizenUserId,
      },
      {
        'title': 'Car Accident on Jalan Raya',
        'type': 'Accident',
        'location': 'Jalan Raya, Lubok Antu',
        'description':
            'Two-vehicle collision reported. Traffic congestion. Police on scene.',
        'status': 'unresolved',
        'priority': 'medium',
        'reporter_name': 'Ali Ahmad',
        'reporter_ic': '920101-14-9876',
        'reporter_contact': '013-5555 6666',
        'date_reported':
            DateTime.now().subtract(Duration(hours: 2)).toIso8601String(),
        'date_updated': null,
        'admin_notes': null,
        'user_id': citizenUserId,
      },
      {
        'title': 'Medical Emergency in Kampung Baru',
        'type': 'Medical Emergency',
        'location': 'Kampung Baru, Lubok Antu',
        'description':
            'Sudden chest pain reported. Ambulance en route. Paramedics assessing patient.',
        'status': 'unresolved',
        'priority': 'high',
        'reporter_name': 'Sarah Lee',
        'reporter_ic': '880520-03-2468',
        'reporter_contact': '014-7777 8888',
        'date_reported':
            DateTime.now().subtract(Duration(hours: 1)).toIso8601String(),
        'date_updated': null,
        'admin_notes': null,
        'user_id': citizenUserId,
      },
      {
        'title': 'Landslide on Bukit Tinggi Road',
        'type': 'Landslide',
        'location': 'Bukit Tinggi Road, Lubok Antu',
        'description':
            'Road blocked by landslide. Heavy rain causing instability. Structural engineers on standby.',
        'status': 'in-progress',
        'priority': 'medium',
        'reporter_name': 'Jane Smith',
        'reporter_ic': '900730-06-5432',
        'reporter_contact': '015-9999 0000',
        'date_reported':
            DateTime.now().subtract(Duration(days: 1)).toIso8601String(),
        'date_updated':
            DateTime.now().subtract(Duration(hours: 5)).toIso8601String(),
        'admin_notes':
            'Road cordoned off. Engineering team assessing stability.',
        'user_id': citizenUserId,
      },
      {
        'title': 'Fire in Taman Indah',
        'type': 'Fire',
        'location': 'Taman Indah, Lubok Antu',
        'description':
            'Small house fire extinguished. Property damage assessed. No injuries reported.',
        'status': 'resolved',
        'priority': 'medium',
        'reporter_name': 'John Doe',
        'reporter_ic': '901234-12-3456',
        'reporter_contact': '011-9876 5432',
        'date_reported':
            DateTime.now().subtract(Duration(days: 4)).toIso8601String(),
        'date_updated':
            DateTime.now().subtract(Duration(days: 3)).toIso8601String(),
        'admin_notes': 'Fire contained. No injuries. Investigation completed.',
        'user_id': citizenUserId,
      },
      {
        'title': 'Car Accident on Jalan Raya Utama',
        'type': 'Accident',
        'location': 'Jalan Raya Utama, Lubok Antu',
        'description':
            'Single vehicle accident. Minor injuries. Towed away.',
        'status': 'resolved',
        'priority': 'low',
        'reporter_name': 'Sarah Lee',
        'reporter_ic': '880520-03-2468',
        'reporter_contact': '014-7777 8888',
        'date_reported':
            DateTime.now().subtract(Duration(days: 5)).toIso8601String(),
        'date_updated':
            DateTime.now().subtract(Duration(days: 4)).toIso8601String(),
        'admin_notes': 'Incident cleared. All parties accounted for.',
        'user_id': citizenUserId,
      },
    ];

    // Generate sequential report IDs: ER2025001, ER2025002, etc.
    int counter = 1;
    final year = DateTime.now().year;

    for (var report in reports) {
      try {
        report['created_at'] = DateTime.now().toIso8601String();
        report['updated_at'] = DateTime.now().toIso8601String();

        // Create custom ID in format ER2025001, ER2025002, etc.
        final reportId =
            'ER$year${counter.toString().padLeft(4, '0')}';

        await _firestore
            .collection('emergency_reports')
            .doc(reportId)
            .set(report);
        print('  ✓ Created report: ${report['title']} (ID: $reportId)');
        counter++;
      } catch (e) {
        print('  ✗ Error creating report ${report['title']}: $e');
        rethrow;
      }
    }
  }

  static Future<void> clearDatabase() async {
    try {
      print('Clearing Firebase database...');

      // Delete all aid programs
      print('Deleting aid programs...');
      final programsSnapshot =
          await _firestore.collection('aid_programs').get();
      for (var doc in programsSnapshot.docs) {
        await doc.reference.delete();
      }
      print('  ✓ Deleted ${programsSnapshot.docs.length} aid programs');

      // Delete all reports
      print('Deleting emergency reports...');
      final reportsSnapshot =
          await _firestore.collection('emergency_reports').get();
      for (var doc in reportsSnapshot.docs) {
        await doc.reference.delete();
      }
      print('  ✓ Deleted ${reportsSnapshot.docs.length} emergency reports');

      // Delete all users from Firestore
      print('Deleting user profiles...');
      final usersSnapshot = await _firestore.collection('users').get();
      for (var doc in usersSnapshot.docs) {
        await doc.reference.delete();
      }
      print('  ✓ Deleted ${usersSnapshot.docs.length} user profiles');

      // Delete metadata counters
      print('Deleting metadata...');
      final metadataSnapshot = await _firestore.collection('_metadata').get();
      for (var doc in metadataSnapshot.docs) {
        await doc.reference.delete();
      }
      print('  ✓ Deleted metadata');

      print('✅ Database cleared successfully!');
      print('Note: Firebase Auth users should be deleted manually from Firebase Console');
    } catch (e) {
      print('❌ Error clearing database: $e');
      rethrow;
    }
  }
}
