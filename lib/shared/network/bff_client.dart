import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

const _bffUrl = String.fromEnvironment('BFF_URL');

final bffClientProvider = Provider<BffClient>((ref) => const BffClient());

class BffClient {
  const BffClient();

  static const _timeout = Duration(seconds: 10);

  Uri _uri(String path) => Uri.parse('$_bffUrl$path');

  Future<Map<String, dynamic>> post(
    String path, {
    required Map<String, dynamic> body,
    String? authToken,
  }) async {
    final response = await http
        .post(
          _uri(path),
          headers: {
            'Content-Type': 'application/json',
            if (authToken != null) 'Authorization': 'Bearer $authToken',
          },
          body: jsonEncode(body),
        )
        .timeout(_timeout);

    if (response.statusCode >= 400) {
      throw BffException(response.statusCode, response.body);
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> postMultipart(
    String path, {
    required Uint8List imageBytes,
    required String filename,
    String? authToken,
  }) async {
    final request = http.MultipartRequest('POST', _uri(path))
      ..files.add(
        http.MultipartFile.fromBytes('file', imageBytes, filename: filename),
      );
    if (authToken != null) {
      request.headers['Authorization'] = 'Bearer $authToken';
    }

    final streamed = await request.send().timeout(_timeout);
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode >= 400) {
      throw BffException(response.statusCode, response.body);
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<dynamic> get(
    String path, {
    String? authToken,
  }) async {
    final response = await http
        .get(
          _uri(path),
          headers: {
            if (authToken != null) 'Authorization': 'Bearer $authToken',
          },
        )
        .timeout(_timeout);

    if (response.statusCode >= 400) {
      throw BffException(response.statusCode, response.body);
    }
    return jsonDecode(response.body);
  }
}

class BffException implements Exception {
  const BffException(this.statusCode, this.body);

  final int statusCode;
  final String body;

  @override
  String toString() => 'BffException($statusCode): $body';
}
