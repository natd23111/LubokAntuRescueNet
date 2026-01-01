import 'package:cloud_firestore/cloud_firestore.dart';

class AidProgramModel {
  final String id;
  final String title;
  final String category;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final String eligibilityCriteria;
  final String aidAmount;
  final String? programType;
  final String status; // active, inactive, draft

  AidProgramModel({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.eligibilityCriteria,
    required this.aidAmount,
    this.programType,
    required this.status,
  });

  // Convert Firestore document to model
  factory AidProgramModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AidProgramModel(
      id: doc.id,
      title: data['title'] ?? '',
      category: data['category'] ?? 'other',
      description: data['description'] ?? '',
      startDate: data['startDate'] is Timestamp
          ? (data['startDate'] as Timestamp).toDate()
          : DateTime.parse(data['startDate'] ?? DateTime.now().toIso8601String()),
      endDate: data['endDate'] is Timestamp
          ? (data['endDate'] as Timestamp).toDate()
          : DateTime.parse(data['endDate'] ?? DateTime.now().toIso8601String()),
      eligibilityCriteria: data['eligibilityCriteria'] ?? '',
      aidAmount: data['aidAmount'] ?? '',
      programType: data['programType'],
      status: data['status'] ?? 'active',
    );
  }

  // Convert model to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'category': category,
      'description': description,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'eligibilityCriteria': eligibilityCriteria,
      'aidAmount': aidAmount,
      'programType': programType,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  // Format dates for display
  String get formattedStartDate {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[startDate.month - 1]} ${startDate.day}, ${startDate.year}';
  }

  String get formattedEndDate {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[endDate.month - 1]} ${endDate.day}, ${endDate.year}';
  }

  String get dateRange => '$formattedStartDate - $formattedEndDate';
}
