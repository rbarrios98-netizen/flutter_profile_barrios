class Project {
  final int id;
  final String title;
  final String domain;
  final String student;
  final String adviser;
  final String status;

  Project({
    required this.id,
    required this.title,
    required this.domain,
    required this.student,
    required this.adviser,
    required this.status,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: (json['id'] is int) ? json['id'] as int : int.parse('${json['id']}'),
      title: json['title'] ?? '',
      domain: json['domain'] ?? '',
      student: json['student'] ?? '',
      adviser: json['adviser'] ?? '',
      status: json['status'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'domain': domain,
    'student': student,
    'adviser': adviser,
    'status': status,
  };
}
