class DiaryModel {
  final int id;
  final int userId;
  final String date;
  final List<Map<String, dynamic>> messages;
  final String? summary;
  final String? emotion;
  final String? color;
  final String createdAt;

  DiaryModel({
    required this.id,
    required this.userId,
    required this.date,
    required this.messages,
    this.summary,
    this.emotion,
    this.color,
    required this.createdAt,
  });

  factory DiaryModel.fromJson(Map<String, dynamic> json) {
    return DiaryModel(
      id: json['id'],
      userId: json['user_id'],
      date: json['date'],
      messages: List<Map<String, dynamic>>.from(json['messages']),
      summary: json['summary'],
      emotion: json['emotion'],
      color: json['color'],
      createdAt: json['created_at'],
    );
  }
}
