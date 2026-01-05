import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseSeeder {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> seedDatabase() async {
    try {
      print('Starting Firebase database seeding...');

      // Use existing admin and citizen user IDs
      // Assumes admin and citizen users already exist in your Firebase project
      print('Using existing admin and citizen users...');
      
      // You can modify these IDs to match your existing users
      const String adminId = 'admin@rescuenet.com'; // Replace with actual admin UID
      const String citizenUserId1 = 'citizen@rescuenet.com'; // Replace with actual citizen UID
      const String citizenUserId2 = 'citizen2@rescuenet.com'; // Additional citizen
      const String citizenUserId3 = 'citizen3@rescuenet.com'; // Additional citizen

      // Create aid programs
      print('Creating aid programs...');
      await _createAidPrograms();

      // Create reports
      print('Creating reports...');
      await _createReports([citizenUserId1, citizenUserId2, citizenUserId3]);

      // Create aid requests
      print('Creating aid requests...');
      await _createAidRequests([citizenUserId1, citizenUserId2, citizenUserId3]);

      // Create notifications
      print('Creating notifications...');
      await _createNotifications(citizenUserId1);

      // Create warnings
      print('Creating warnings...');
      await _createWarnings();

      print('✅ Firebase seeding completed successfully!');
    } catch (e) {
      print('❌ Error seeding database: $e');
      rethrow;
    }
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

    // Generate sequential program IDs: AID2026001, AID2026002, etc.
    int counter = 1;
    final year = DateTime.now().year;

    for (var program in programs) {
      try {
        program['created_at'] = DateTime.now().toIso8601String();
        program['updated_at'] = DateTime.now().toIso8601String();

        // Create custom ID in format AID2026001, AID2026002, etc.
        final programId = 'AID$year${counter.toString().padLeft(3, '0')}';

        await _firestore
            .collection('aid_programs')
            .doc(programId)
            .set(program);
        print('  ✓ Created program: ${program['title']} (ID: $programId)');
        counter++;
      } catch (e) {
        print('  ✗ Error creating program ${program['title']}: $e');
        rethrow;
      }
    }
  }

  static Future<void> _createReports(List<String> userIds) async {
    if (userIds.isEmpty) {
      print('  ⚠ No user IDs provided for reports');
      return;
    }

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
        'user_id': userIds[0],
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
        'user_id': userIds[1] ?? userIds[0],
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
        'user_id': userIds[2] ?? userIds[0],
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
        'user_id': userIds[1] ?? userIds[0],
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
        'user_id': userIds[0],
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
        'user_id': userIds[2] ?? userIds[0],
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
        'user_id': userIds[1] ?? userIds[0],
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
        'user_id': userIds[0],
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

  static Future<void> _createAidRequests(List<String> userIds) async {
    if (userIds.isEmpty) {
      print('  ⚠ No user IDs provided for aid requests');
      return;
    }

    final requests = [
      {
        'user_id': userIds[0],
        'program_id': 'AID2026001',
        'status': 'approved',
        'title': 'B40 Assistance Application',
        'description': 'Applied for monthly household assistance',
        'date_submitted': DateTime.now().subtract(Duration(days: 10)).toIso8601String(),
        'date_approved': DateTime.now().subtract(Duration(days: 5)).toIso8601String(),
      },
      {
        'user_id': userIds[1] ?? userIds[0],
        'program_id': 'AID2026003',
        'status': 'pending',
        'title': 'Medical Assistance Application',
        'description': 'Requesting financial aid for emergency hospitalization',
        'date_submitted': DateTime.now().subtract(Duration(days: 3)).toIso8601String(),
        'date_approved': null,
      },
    ];

    int counter = 1;
    for (var request in requests) {
      try {
        request['created_at'] = DateTime.now().toIso8601String();
        request['updated_at'] = DateTime.now().toIso8601String();

        final requestId = 'AR2026${counter.toString().padLeft(3, '0')}';

        await _firestore.collection('aid_requests').doc(requestId).set(request);
        print('  ✓ Created aid request: ${request['title']} (ID: $requestId)');
        counter++;
      } catch (e) {
        print('  ✗ Error creating aid request: $e');
        rethrow;
      }
    }
  }

  static Future<void> _createNotifications(String userId) async {
    final notifications = [
      {
        'title': 'Aid Application Approved',
        'body': 'Your B40 application has been approved.',
        'type': 'aid_update',
        'timestamp': Timestamp.fromDate(DateTime.now().subtract(Duration(days: 1))),
        'isRead': false,
      },
      {
        'title': 'Emergency Report Update',
        'body': 'Your flood report has been resolved.',
        'type': 'report_status',
        'timestamp': Timestamp.fromDate(DateTime.now().subtract(Duration(hours: 5))),
        'isRead': true,
      },
    ];

    int counter = 1;
    for (var notification in notifications) {
      try {
        final notificationId = 'NOTIF${DateTime.now().year}${counter.toString().padLeft(4, '0')}';

        await _firestore
            .collection('users')
            .doc(userId)
            .collection('notifications')
            .doc(notificationId)
            .set(notification);
        print('  ✓ Created notification: ${notification['title']}');
        counter++;
      } catch (e) {
        print('  ✗ Error creating notification: $e');
        rethrow;
      }
    }
  }

  static Future<void> _createWarnings() async {
    final warnings = [
      {
        'id': 'WARN2026001',
        'type': 'Flood',
        'location': 'Jalan Sungai Besar',
        'severity': 'high',
        'distance': 0.8,
        'description': 'Flash flood warning due to heavy rainfall.',
        'timestamp': DateTime.now().subtract(Duration(hours: 1)).toIso8601String(),
        'latitude': 3.4156,
        'longitude': 102.7369,
        'status': 'active',
      },
      {
        'id': 'WARN2026002',
        'type': 'Landslide',
        'location': 'Bukit Tinggi Road',
        'severity': 'medium',
        'distance': 1.5,
        'description': 'Landslide risk high due to soil instability.',
        'timestamp': DateTime.now().subtract(Duration(hours: 2)).toIso8601String(),
        'latitude': 3.4201,
        'longitude': 102.7401,
        'status': 'active',
      },
    ];

    for (var warning in warnings) {
      try {
        final warningId = warning['id'] as String;
        await _firestore.collection('warnings').doc(warningId).set(warning);
        print('  ✓ Created warning: ${warning['location']}');
      } catch (e) {
        print('  ✗ Error creating warning: $e');
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
