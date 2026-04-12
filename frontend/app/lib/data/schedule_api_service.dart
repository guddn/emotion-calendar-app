import 'dart:convert';
import 'package:http/http.dart' as http;
import 'schedule.dart';

class ScheduleApiService {
  static const String _baseUrl = 'https://helloguddn-emotion-calendar-app.hf.space';

  static Future<ScheduleModel?> saveSchedule({
    required int userId,
    required String title,
    String? description,
    required String dueDate, // YYYY-MM-DD
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/schedule'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'title': title,
        'description': description,
        'due_date': dueDate,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) return null;

    final json = jsonDecode(utf8.decode(response.bodyBytes));
    return ScheduleModel.fromJson(json);
  }

  static Future<List<ScheduleModel>> fetchSchedulesByMonth({
    required int userId,
    required int year,
    required int month,
  }) async {
    final monthStr = '$year-${month.toString().padLeft(2, '0')}';
    final uri = Uri.parse('$_baseUrl/schedule').replace(
      queryParameters: {'user_id': '$userId', 'month': monthStr},
    );

    final response = await http.get(uri);

    if (response.statusCode == 404) return [];
    if (response.statusCode != 200) {
      throw Exception('일정 조회 실패: ${response.statusCode}');
    }

    final List<dynamic> jsonList = jsonDecode(utf8.decode(response.bodyBytes));
    return jsonList.map((e) => ScheduleModel.fromJson(e)).toList();
  }

  static Future<List<ScheduleModel>> fetchSchedulesByDate({
    required int userId,
    required DateTime date,
  }) async {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final uri = Uri.parse('$_baseUrl/schedule').replace(
      queryParameters: {'user_id': '$userId', 'date': dateStr},
    );

    final response = await http.get(uri);

    if (response.statusCode == 404) return [];
    if (response.statusCode != 200) {
      throw Exception('일정 조회 실패: ${response.statusCode}');
    }

    final List<dynamic> jsonList = jsonDecode(utf8.decode(response.bodyBytes));
    return jsonList.map((e) => ScheduleModel.fromJson(e)).toList();
  }
}