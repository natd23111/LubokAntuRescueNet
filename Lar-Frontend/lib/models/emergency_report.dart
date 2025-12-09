class EmergencyReport {
  final int id;
  final String incidentType;
  final String incidentLocation;
  final String description;
  final String status;
  final String? incidentPhoto;
  final DateTime createdAt;

  EmergencyReport({
    required this.id,
    required this.incidentType,
    required this.incidentLocation,
    required this.description,
    required this.status,
    this.incidentPhoto,
    required this.createdAt,
  });

  factory EmergencyReport.fromJson(Map<String, dynamic> json) {
    return EmergencyReport(
      id: json['id'],
      incidentType: json['incident_type'],
      incidentLocation: json['incident_location'],
      description: json['description'] ?? '',
      status: json['status'],
      incidentPhoto: json['incident_photo'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
