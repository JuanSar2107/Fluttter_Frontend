import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../storage/secure_store.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';

class ApiException implements Exception {
  const ApiException(this.statusCode, this.message, [this.detail]);

  final int statusCode;
  final String message;
  final dynamic detail;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({
    required this.secureStore,
    http.Client? httpClient,
    this.baseUrl = ApiConfig.baseUrl,
  }) : _httpClient = httpClient ?? http.Client();

  final SecureStore secureStore;
  final http.Client _httpClient;
  final String baseUrl;

  static const String _tokenKey = 'aero_parts.session.token';

  Future<Map<String, String>> _headers({
    bool requiresAuth = true,
    String? tokenOverride,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (tokenOverride != null && tokenOverride.isNotEmpty) {
      headers['Authorization'] = 'Bearer $tokenOverride';
    } else if (requiresAuth) {
      final token = await secureStore.read(_tokenKey);
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  Future<dynamic> get(
    String path, {
    bool requiresAuth = true,
    String? tokenOverride,
    Map<String, dynamic>? queryParameters,
  }) async {
    var uri = Uri.parse('$baseUrl$path');
    if (queryParameters != null && queryParameters.isNotEmpty) {
      uri = uri.replace(
        queryParameters: queryParameters.map(
          (k, v) => MapEntry(k, v.toString()),
        ),
      );
    }

    final headers = await _headers(
      requiresAuth: requiresAuth,
      tokenOverride: tokenOverride,
    );

    final response = await _httpClient.get(uri, headers: headers);
    return _handleResponse(response);
  }

  Future<dynamic> post(
    String path, {
    dynamic body,
    bool requiresAuth = true,
    String? tokenOverride,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = await _headers(
      requiresAuth: requiresAuth,
      tokenOverride: tokenOverride,
    );

    final response = await _httpClient.post(
      uri,
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  Future<dynamic> put(
    String path, {
    dynamic body,
    bool requiresAuth = true,
    String? tokenOverride,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = await _headers(
      requiresAuth: requiresAuth,
      tokenOverride: tokenOverride,
    );

    final response = await _httpClient.put(
      uri,
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  Future<dynamic> delete(
    String path, {
    bool requiresAuth = true,
    String? tokenOverride,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = await _headers(
      requiresAuth: requiresAuth,
      tokenOverride: tokenOverride,
    );

    final response = await _httpClient.delete(uri, headers: headers);
    return _handleResponse(response);
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(utf8.decode(response.bodyBytes));
    }

    String message = 'Error en el servidor (${response.statusCode})';
    dynamic detail;
    try {
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      if (json is Map && json['detail'] != null) {
        detail = json['detail'];
        if (detail is String) {
          message = detail;
        } else if (detail is List && detail.isNotEmpty) {
          final first = detail.first;
          if (first is Map && first['msg'] != null) {
            message = first['msg'].toString();
          }
        }
      }
    } catch (_) {}

    throw ApiException(response.statusCode, message, detail);
  }
}

final apiClientProvider = Provider<ApiClient>((ref) {
  final secureStore = ref.watch(secureStoreProvider);
  return ApiClient(secureStore: secureStore);
});
