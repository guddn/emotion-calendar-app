import 'dart:convert';
import 'package:http/http.dart' as http;

class UserModel {
  final int id;
  final String email;
  final String nickname;

  const UserModel({
    required this.id,
    required this.email,
    required this.nickname,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as int,
        email: (json['email'] as String?) ?? '',
        nickname: (json['nickname'] as String?) ?? '',
      );
}

class UserApiService {
  static const String _baseUrl =
      'https://helloguddn-emotion-calendar-app.hf.space';

  /// 이메일 + 닉네임으로 로그인. 없는 사용자면 null 반환, 서버 오류면 예외.
  static Future<UserModel?> login({
    required String email,
    required String nickname,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'nickname': nickname}),
    );

    if (response.statusCode == 401 || response.statusCode == 404) return null;
    if (response.statusCode != 200) {
      throw Exception('서버 오류: ${response.statusCode}');
    }

    return UserModel.fromJson(
      jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
    );
  }
}
