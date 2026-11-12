import 'package:flutter/foundation.dart';

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/lecturer.dart';
import 'lecturer_repository.dart';

const _apiBaseUrlOverride = String.fromEnvironment('API_BASE_URL');
const _localhostApiBaseUrl = 'http://localhost:3000/api';
const _androidEmulatorApiBaseUrl = 'http://10.0.2.2:3000/api';

String get apiBaseUrl {
  if (_apiBaseUrlOverride.isNotEmpty) return _apiBaseUrlOverride;
  return defaultTargetPlatform == TargetPlatform.android
      ? _androidEmulatorApiBaseUrl
      : _localhostApiBaseUrl;
}

class LecturerApi implements LecturerRepository {
  LecturerApi({String? baseUrl, this._token, http.Client? client})
    : _baseUrl = (baseUrl ?? apiBaseUrl).replaceFirst(RegExp(r'/$'), ''),
      _client = client ?? http.Client();

  final String _baseUrl;
  final String? _token;
  final http.Client _client;

  Uri get _lecturersUri => Uri.parse('$_baseUrl/lecturers');

  @override
  Future<List<Lecturer>> getAll() async {
    final response = await _client.get(_lecturersUri, headers: _authHeaders);
    final data = _decodeResponse(response);
    if (data is! List) {
      throw const FormatException('Dữ liệu danh sách không hợp lệ.');
    }

    return data.map((item) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('Thông tin giảng viên không hợp lệ.');
      }
      return Lecturer.fromJson(item);
    }).toList();
  }

  @override
  Future<void> create(LecturerDraft lecturer) async {
    final response = await _client.post(
      _lecturersUri,
      headers: _authHeaders..['Content-Type'] = 'application/json',
      body: jsonEncode(lecturer.toJson()),
    );
    _decodeResponse(response);
  }

  @override
  Future<void> update(Lecturer lecturer) async {
    final response = await _client.put(
      _lecturerUri(lecturer.id),
      headers: _authHeaders..['Content-Type'] = 'application/json',
      body: jsonEncode(lecturer.toJson()),
    );
    _decodeResponse(response);
  }

  @override
  Future<void> delete(String id) async {
    final response = await _client.delete(
      _lecturerUri(id),
      headers: _authHeaders,
    );
    _decodeResponse(response);
  }

  Uri _lecturerUri(String id) =>
      Uri.parse('$_baseUrl/lecturers/${Uri.encodeComponent(id)}');

  Map<String, String> get _authHeaders => {
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  dynamic _decodeResponse(http.Response response) {
    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        response.body.isEmpty) {
      return null;
    }

    dynamic data;
    try {
      data = jsonDecode(response.body);
    } on FormatException {
      throw const FormatException('Máy chủ trả về dữ liệu không hợp lệ.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = data is Map<String, dynamic> && data['error'] is String
          ? data['error'] as String
          : 'Yêu cầu thất bại (${response.statusCode}).';
      throw ApiException(message, response.statusCode);
    }
    return data;
  }
}

class ApiException implements Exception {
  const ApiException(this.message, this.statusCode);

  final String message;
  final int statusCode;

  @override
  String toString() => message;
}
