import 'dart:convert';
import 'package:flutter/material.dart';
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

  /// 해당 월의 날짜별 감정 색상을 반환합니다.
  static Future<Map<DateTime, Color>> fetchEmotionsByMonth({
    required int userId,
    required DateTime month,
  }) async {
    final monthStr =
        '${month.year}-${month.month.toString().padLeft(2, '0')}';
    final uri = Uri.parse('$_baseUrl/diary/month')
        .replace(queryParameters: {'user_id': '$userId', 'month': monthStr});

    final response = await http.get(uri);
    if (response.statusCode != 200) return {};

    final List<dynamic> list = jsonDecode(utf8.decode(response.bodyBytes));
    final Map<DateTime, Color> result = {};
    for (final item in list) {
      final parts = ((item['date'] as String?) ?? '').split('-');
      if (parts.length != 3) continue;
      final date = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
      final hex = (item['color'] as String?) ?? '';
      if (hex.isNotEmpty) result[date] = _colorFromHex(hex);
    }
    return result;
  }

  static Color _colorFromHex(String hex) {
    var v = hex.replaceFirst('#', '').trim();
    if (v.length == 6) v = 'FF$v';
    return Color(int.tryParse(v, radix: 16) ?? 0xFFFFFFFF);
  }
}