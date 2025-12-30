class AidRequest {
  final String id;
  final String title;
  final String description;
  final String status;
  final DateTime dateSubmitted;

  AidRequest({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.dateSubmitted,
  });

  factory AidRequest.fromJson(Map<String, dynamic> json) {
    return AidRequest(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 'pending',
      dateSubmitted: json['date_submitted'] != null
          ? DateTime.parse(json['date_submitted'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status,
      'date_submitted': dateSubmitted.toIso8601String(),
    };
  }
}
