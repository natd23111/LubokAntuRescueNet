import 'package:cloud_firestore/cloud_firestore.dart';

class AidRequestModel {
  final String id;
  final String userId;
  final String requestId;
  final String aidType;
  final String status;
  final DateTime submissionDate;
  final String description;
  final List<FamilyMemberModel> familyMembers;
  final double monthlyIncome;
  final DateTime createdAt;
  final String? applicantName;
  final String? applicantIC;
  final String? applicantEmail;
  final String? applicantPhone;
  final String? applicantAddress;

  AidRequestModel({
    required this.id,
    required this.userId,
    required this.requestId,
    required this.aidType,
    required this.status,
    required this.submissionDate,
    required this.description,
    required this.familyMembers,
    required this.monthlyIncome,
    required this.createdAt,
    this.applicantName,
    this.applicantIC,
    this.applicantEmail,
    this.applicantPhone,
    this.applicantAddress,
  });

  factory AidRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AidRequestModel(
      id: doc.id,
      userId: data['user_id'] ?? '',
      requestId: data['request_id'] ?? '',
      aidType: data['aid_type'] ?? '',
      status: data['status'] ?? 'pending',
      submissionDate: data['submission_date'] != null
          ? (data['submission_date'] is Timestamp
                ? (data['submission_date'] as Timestamp).toDate()
                : DateTime.parse(data['submission_date']))
          : DateTime.now(),
      description: data['description'] ?? '',
      familyMembers: (data['family_members'] as List<dynamic>? ?? [])
          .map((e) => FamilyMemberModel.fromMap(e as Map<String, dynamic>))
          .toList(),
      monthlyIncome: (data['monthly_income'] ?? 0).toDouble(),
      createdAt: data['created_at'] != null
          ? (data['created_at'] is Timestamp
                ? (data['created_at'] as Timestamp).toDate()
                : DateTime.parse(data['created_at']))
          : DateTime.now(),
      applicantName: data['applicant_name'] ?? data['full_name'],
      applicantIC: data['applicant_ic'] ?? data['ic_number'],
      applicantEmail: data['applicant_email'] ?? data['email'],
      applicantPhone: data['applicant_phone'] ?? data['phone'],
      applicantAddress: data['applicant_address'] ?? data['address'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'request_id': requestId,
      'aid_type': aidType,
      'status': status,
      'submission_date': submissionDate,
      'description': description,
      'family_members': familyMembers.map((fm) => fm.toMap()).toList(),
      'monthly_income': monthlyIncome,
      'created_at': createdAt,
      'applicant_name': applicantName,
      'applicant_ic': applicantIC,
      'applicant_email': applicantEmail,
      'applicant_phone': applicantPhone,
      'applicant_address': applicantAddress,
    };
  }

  String get formattedDate {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[submissionDate.month - 1]} ${submissionDate.day}, ${submissionDate.year}';
  }
}

class FamilyMemberModel {
  final String name;
  final String status;

  FamilyMemberModel({required this.name, required this.status});

  factory FamilyMemberModel.fromMap(Map<String, dynamic> map) {
    return FamilyMemberModel(
      name: map['name'] ?? '',
      status: map['status'] ?? 'student',
    );
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'status': status};
  }
}
