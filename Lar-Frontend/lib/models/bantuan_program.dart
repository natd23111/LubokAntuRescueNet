class BantuanProgram {
  final int id;
  final String title;
  final String description;
  final String? criteria;
  final String status;

  BantuanProgram({
    required this.id,
    required this.title,
    required this.description,
    this.criteria,
    required this.status,
  });

  factory BantuanProgram.fromJson(Map<String, dynamic> json) {
    return BantuanProgram(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      criteria: json['criteria'],
      status: json['status'],
    );
  }
}
