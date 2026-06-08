import 'dart:convert';
import 'package:http/http.dart' as http;
import 'schedule.dart';

class ScheduleApiService {
  static const String _baseUrl = 'https://helloguddn-emotion-calendar-app.hf.space';

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