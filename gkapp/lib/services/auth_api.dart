import 'dart:convert';

import 'package:http/http.dart' as http;

import 'lecturer_api.dart';

class AuthApi {
  AuthApi({String? baseUrl, http.Client? client})
    : _baseUrl = (baseUrl ?? apiBaseUrl).replaceFirst(RegExp(r'/$'), ''),
      _client = client ?? http.Client();

  final String _baseUrl;
  final http.Client _client;

  Future<String> login(String username, String password) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    dynamic data;
    try {
      data = jsonDecode(response.body);
    } on FormatException {
      throw const AuthApiException('Máy chủ trả về dữ liệu không hợp lệ.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = data is Map<String, dynamic> && data['error'] is String
          ? data['error'] as String
          : 'Đăng nhập thất bại (${response.statusCode}).';
      throw AuthApiException(message, response.statusCode);
    }
    if (data is! Map<String, dynamic> ||
        data['token'] is! String ||
        (data['token'] as String).isEmpty) {
      throw const AuthApiException('Máy chủ trả về token không hợp lệ.');
    }
    return data['token'] as String;
  }
}

class AuthApiException implements Exception {
  const AuthApiException(this.message, [this.statusCode]);

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
