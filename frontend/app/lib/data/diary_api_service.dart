import 'dart:convert';
import 'package:http/http.dart' as http;
import 'diary.dart';

class DiaryApiService {
  static const String _baseUrl = 'https://helloguddn-emotion-calendar-app.hf.space';

  static Future<DiaryModel?> saveDiary({
    required int userId,
    required DateTime date,
    required List<Map<String, dynamic>> messages,
    String? summary,
    String? emotion,
    String? color,
  }) async {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    final response = await http.post(
      Uri.parse('$_baseUrl/diary'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'date': dateStr,
        'messages': messages,
        'summary': summary,
        'emotion': emotion,
        'color': color,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) return null;

    final json = jsonDecode(utf8.decode(response.bodyBytes));
    return DiaryModel.fromJson(json);
  }

  static Future<DiaryModel?> fetchDiary({
    required int userId,
    required DateTime date,
  }) async {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    final uri = Uri.parse('$_baseUrl/diary')
        .replace(queryParameters: {'user_id': '$userId', 'date': dateStr});

    final response = await http.get(uri);

    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) {
      throw Exception('일기 조회 실패: ${response.statusCode}');
    }

    final json = jsonDecode(utf8.decode(response.bodyBytes));
    return DiaryModel.fromJson(json);
  }
}