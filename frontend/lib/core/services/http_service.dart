import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:vetmate/core/constants/app_constants.dart';

class HttpService {
  final FlutterSecureStorage _storage;
  final http.Client _client;

  HttpService({FlutterSecureStorage? storage, http.Client? client})
    : _storage = storage ?? const FlutterSecureStorage(),
      _client = client ?? http.Client();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _storage.read(key: AppConstants.keyAccessToken);
    return {
      HttpHeaders.contentTypeHeader: 'application/json; charset=UTF-8',
      HttpHeaders.acceptHeader: 'application/json',
      if (token != null) HttpHeaders.authorizationHeader: 'Bearer $token',
    };
  }

  Future<http.Response> get(
    String path, {
    Map<String, String>? queryParameters,
  }) async {
    var uri = Uri.parse('${AppConstants.apiBaseUrl}$path');
    if (queryParameters != null) {
      uri = uri.replace(queryParameters: queryParameters);
    }
    final headers = await _getHeaders();
    final response = await _client.get(uri, headers: headers);
    _checkResponse(response);
    return response;
  }

  Future<http.Response> post(String path, {Object? body}) async {
    final uri = Uri.parse('${AppConstants.apiBaseUrl}$path');
    final headers = await _getHeaders();
    final response = await _client.post(
      uri,
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
    _checkResponse(response);
    return response;
  }

  Future<http.Response> put(String path, {Object? body}) async {
    final uri = Uri.parse('${AppConstants.apiBaseUrl}$path');
    final headers = await _getHeaders();
    final response = await _client.put(
      uri,
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
    _checkResponse(response);
    return response;
  }

  Future<http.Response> delete(String path) async {
    final uri = Uri.parse('${AppConstants.apiBaseUrl}$path');
    final headers = await _getHeaders();
    final response = await _client.delete(uri, headers: headers);
    _checkResponse(response);
    return response;
  }

  void _checkResponse(http.Response response) {
    if (response.statusCode >= 400) {
      String message;
      try {
        final parsed = jsonDecode(response.body);
        message = parsed['message'] ?? parsed['error'] ?? 'API request failed';
      } catch (_) {
        message = 'Server returned status code ${response.statusCode}';
      }
      throw HttpException(message);
    }
  }
}

final httpServiceProvider = Provider<HttpService>((ref) {
  return HttpService();
});
