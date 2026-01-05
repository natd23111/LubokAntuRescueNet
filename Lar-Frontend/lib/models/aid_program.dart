class AidProgram {
  final dynamic id;
  final String title;
  final String category;
  final String status;
  final DateTime startDate;
  final DateTime endDate;
  final String? description;
  final String? aidAmount;
  final String? eligibilityCriteria;
  final String? programType;

  AidProgram({
    required this.id,
    required this.title,
    required this.category,
    required this.status,
    required this.startDate,
    required this.endDate,
    this.description,
    this.aidAmount,
    this.eligibilityCriteria,
    this.programType,
  });

  factory AidProgram.fromJson(Map<String, dynamic> json) {
    return AidProgram(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      category: json['category'] ?? 'other',
      status: _mapStatusToLowerCase(json['status'] ?? 'Active'),
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'])
          : DateTime.now(),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'])
          : DateTime.now(),
      description: json['description'],
      aidAmount: json['aid_amount']?.toString(),
      eligibilityCriteria: json['criteria'],
      programType: json['program_type'],
    );
  }

  static String _mapStatusToLowerCase(String status) {
    return status.toLowerCase();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'status': status,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'description': description,
      'aid_amount': aidAmount,
      'eligibility_criteria': eligibilityCriteria,
      'program_type': programType,
    };
  }
}
