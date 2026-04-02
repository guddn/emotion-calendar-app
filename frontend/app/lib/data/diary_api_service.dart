import 'dart:convert';
import 'package:http/http.dart' as http;
import 'diary.dart';

class DiaryApiService {
  static const String _baseUrl = 'https://helloguddn-emotion-calendar-app.hf.space';

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