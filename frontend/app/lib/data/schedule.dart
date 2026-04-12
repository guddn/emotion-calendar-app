class ScheduleModel {
  final int id;
  final int userId;
  final String title;
  final String? description;
  final String dueDate; // YYYY-MM-DD
  final bool isDone;
  final String createdAt;

  ScheduleModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.dueDate,
    required this.isDone,
    required this.createdAt,
  });

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    return ScheduleModel(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      description: json['description'],
      dueDate: (json['due_date'] ?? json['scheduled_at'] ?? '').toString().substring(0, 10),
      isDone: json['is_done'] ?? false,
      createdAt: json['created_at'] ?? '',
    );
  }
}