import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../auth/auth_service.dart';
import '../config/app_config.dart';

/// Custom Exception for API Communication Errors
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final dynamic details;

  ApiException({
    required this.statusCode,
    required this.message,
    this.details,
  });

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Reusable HTTP Client for FastAPI Backend Communication.
/// Automatically attaches Bearer token from Supabase session,
/// handles timeouts, JSON serialization, and sanitized logging.
class ApiClient {
  final AppConfig config;
  final AuthService _authService;
  final http.Client _httpClient;

  ApiClient({
    AppConfig? config,
    AuthService? authService,
    http.Client? httpClient,
  })  : config = config ?? AppConfig.development(),
        _authService = authService ?? AuthService(),
        _httpClient = httpClient ?? http.Client();

  /// Safe logging that masks sensitive tokens
  void _log(String method, Uri uri, {int? statusCode, String? error}) {
    if (kDebugMode && config.enableDebugTelemetry) {
      if (error != null) {
        debugPrint('[ApiClient] $method $uri ✗ Error: $error');
      } else {
        debugPrint('[ApiClient] $method $uri -> Status: $statusCode');
      }
    }
  }

  /// Constructs common HTTP headers, injecting Bearer token when available
  Future<Map<String, String>> _buildHeaders({
    Map<String, String>? extraHeaders,
    bool requiresAuth = true,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requiresAuth) {
      final token = await _authService.getAccessToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }

    return headers;
  }

  /// Processes HTTP responses and converts non-2xx into ApiExceptions
  dynamic _handleResponse(http.Response response) {
    final statusCode = response.statusCode;

    // 200 - 299: Success
    if (statusCode >= 200 && statusCode < 300) {
      if (response.body.isEmpty) return null;
      try {
        return jsonDecode(response.body);
      } catch (_) {
        return response.body;
      }
    }

    // Parse backend error details
    String errorMessage = 'HTTP Error $statusCode';
    dynamic errorDetails;

    try {
      final errorJson = jsonDecode(response.body);
      if (errorJson is Map<String, dynamic> && errorJson.containsKey('detail')) {
        final detail = errorJson['detail'];
        errorMessage = detail is String ? detail : jsonEncode(detail);
        errorDetails = detail;
      }
    } catch (_) {
      if (response.body.isNotEmpty) {
        errorMessage = response.body;
      }
    }

    if (statusCode == 401) {
      throw ApiException(
        statusCode: 401,
        message: 'Unauthorized: Session expired or invalid. Please sign in again.',
        details: errorDetails,
      );
    }

    if (statusCode == 403) {
      throw ApiException(
        statusCode: 403,
        message: 'Forbidden: Access denied to this neural resource.',
        details: errorDetails,
      );
    }

    throw ApiException(
      statusCode: statusCode,
      message: errorMessage,
      details: errorDetails,
    );
  }

  /// GET Request
  Future<dynamic> get(
    String endpoint, {
    Map<String, String>? queryParams,
    Map<String, String>? headers,
    bool requiresAuth = true,
  }) async {
    final baseUri = Uri.parse('${config.apiBaseUrl}$endpoint');
    final uri = queryParams != null
        ? baseUri.replace(queryParameters: queryParams)
        : baseUri;

    try {
      final requestHeaders = await _buildHeaders(
        extraHeaders: headers,
        requiresAuth: requiresAuth,
      );

      final response = await _httpClient
          .get(uri, headers: requestHeaders)
          .timeout(config.timeout);

      _log('GET', uri, statusCode: response.statusCode);
      return _handleResponse(response);
    } on SocketException catch (e) {
      _log('GET', uri, error: 'SocketException: ${e.message}');
      throw ApiException(
        statusCode: 503,
        message: 'Unable to reach TESS backend server at ${config.apiBaseUrl}. Verify network connection.',
      );
    } on TimeoutException {
      _log('GET', uri, error: 'Timeout after ${config.timeout.inSeconds}s');
      throw ApiException(
        statusCode: 408,
        message: 'Request timed out after ${config.timeout.inSeconds} seconds.',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      _log('GET', uri, error: e.toString());
      throw ApiException(statusCode: 500, message: e.toString());
    }
  }

  /// POST Request
  Future<dynamic> post(
    String endpoint, {
    dynamic body,
    Map<String, String>? headers,
    bool requiresAuth = true,
  }) async {
    final uri = Uri.parse('${config.apiBaseUrl}$endpoint');

    try {
      final requestHeaders = await _buildHeaders(
        extraHeaders: headers,
        requiresAuth: requiresAuth,
      );

      final encodedBody = body != null ? jsonEncode(body) : null;

      final response = await _httpClient
          .post(uri, headers: requestHeaders, body: encodedBody)
          .timeout(config.timeout);

      _log('POST', uri, statusCode: response.statusCode);
      return _handleResponse(response);
    } on SocketException catch (e) {
      _log('POST', uri, error: 'SocketException: ${e.message}');
      throw ApiException(
        statusCode: 503,
        message: 'Unable to reach TESS backend server at ${config.apiBaseUrl}.',
      );
    } on TimeoutException {
      _log('POST', uri, error: 'Timeout');
      throw ApiException(
        statusCode: 408,
        message: 'Request timed out after ${config.timeout.inSeconds} seconds.',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      _log('POST', uri, error: e.toString());
      throw ApiException(statusCode: 500, message: e.toString());
    }
  }

  /// PUT Request
  Future<dynamic> put(
    String endpoint, {
    dynamic body,
    Map<String, String>? headers,
    bool requiresAuth = true,
  }) async {
    final uri = Uri.parse('${config.apiBaseUrl}$endpoint');

    try {
      final requestHeaders = await _buildHeaders(
        extraHeaders: headers,
        requiresAuth: requiresAuth,
      );

      final encodedBody = body != null ? jsonEncode(body) : null;

      final response = await _httpClient
          .put(uri, headers: requestHeaders, body: encodedBody)
          .timeout(config.timeout);

      _log('PUT', uri, statusCode: response.statusCode);
      return _handleResponse(response);
    } on SocketException catch (e) {
      _log('PUT', uri, error: 'SocketException: ${e.message}');
      throw ApiException(
        statusCode: 503,
        message: 'Unable to reach TESS backend server at ${config.apiBaseUrl}.',
      );
    } on TimeoutException {
      _log('PUT', uri, error: 'Timeout');
      throw ApiException(
        statusCode: 408,
        message: 'Request timed out after ${config.timeout.inSeconds} seconds.',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      _log('PUT', uri, error: e.toString());
      throw ApiException(statusCode: 500, message: e.toString());
    }
  }

  /// DELETE Request
  Future<dynamic> delete(
    String endpoint, {
    Map<String, String>? headers,
    bool requiresAuth = true,
  }) async {
    final uri = Uri.parse('${config.apiBaseUrl}$endpoint');

    try {
      final requestHeaders = await _buildHeaders(
        extraHeaders: headers,
        requiresAuth: requiresAuth,
      );

      final response = await _httpClient
          .delete(uri, headers: requestHeaders)
          .timeout(config.timeout);

      _log('DELETE', uri, statusCode: response.statusCode);
      return _handleResponse(response);
    } on SocketException catch (e) {
      _log('DELETE', uri, error: 'SocketException: ${e.message}');
      throw ApiException(
        statusCode: 503,
        message: 'Unable to reach TESS backend server at ${config.apiBaseUrl}.',
      );
    } on TimeoutException {
      _log('DELETE', uri, error: 'Timeout');
      throw ApiException(
        statusCode: 408,
        message: 'Request timed out after ${config.timeout.inSeconds} seconds.',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      _log('DELETE', uri, error: e.toString());
      throw ApiException(statusCode: 500, message: e.toString());
    }
  }

  /// Check Backend Health (/health)
  Future<bool> checkHealth() async {
    try {
      final data = await get('/health', requiresAuth: false);
      return data is Map && data['status'] == 'ok';
    } catch (_) {
      return false;
    }
  }

  /// POST Multipart (File Upload for STT Audio and Screen Captures)
  Future<dynamic> postMultipart(
    String endpoint, {
    required List<int> fileBytes,
    required String filename,
    required String fieldName,
    Map<String, String>? fields,
    Map<String, String>? headers,
    bool requiresAuth = true,
  }) async {
    final uri = Uri.parse('${config.apiBaseUrl}$endpoint');
    final request = http.MultipartRequest('POST', uri);

    if (requiresAuth) {
      final token = await _authService.getAccessToken();
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
    }
    if (headers != null) {
      request.headers.addAll(headers);
    }
    if (fields != null) {
      request.fields.addAll(fields);
    }

    request.files.add(
      http.MultipartFile.fromBytes(
        fieldName,
        fileBytes,
        filename: filename,
      ),
    );

    try {
      final streamedResponse = await _httpClient.send(request).timeout(config.timeout);
      final response = await http.Response.fromStream(streamedResponse);
      _log('POST (Multipart)', uri, statusCode: response.statusCode);
      return _handleResponse(response);
    } on SocketException catch (e) {
      _log('POST (Multipart)', uri, error: 'SocketException: ${e.message}');
      throw ApiException(
        statusCode: 503,
        message: 'Unable to reach TESS backend server at ${config.apiBaseUrl}.',
      );
    } on TimeoutException {
      _log('POST (Multipart)', uri, error: 'Timeout after ${config.timeout.inSeconds}s');
      throw ApiException(
        statusCode: 408,
        message: 'Request timed out after ${config.timeout.inSeconds} seconds.',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      _log('POST (Multipart)', uri, error: e.toString());
      throw ApiException(statusCode: 500, message: e.toString());
    }
  }

  /// POST Request returning raw bytes (e.g. for TTS audio/wav responses)
  Future<Uint8List> postForBytes(
    String endpoint, {
    dynamic body,
    Map<String, String>? headers,
    bool requiresAuth = true,
  }) async {
    final uri = Uri.parse('${config.apiBaseUrl}$endpoint');
    try {
      final requestHeaders = await _buildHeaders(
        extraHeaders: headers,
        requiresAuth: requiresAuth,
      );
      final encodedBody = body != null ? jsonEncode(body) : null;
      final response = await _httpClient
          .post(uri, headers: requestHeaders, body: encodedBody)
          .timeout(config.timeout);

      _log('POST (Bytes)', uri, statusCode: response.statusCode);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response.bodyBytes;
      }
      _handleResponse(response);
      return Uint8List(0);
    } on SocketException catch (e) {
      _log('POST (Bytes)', uri, error: 'SocketException: ${e.message}');
      throw ApiException(
        statusCode: 503,
        message: 'Unable to reach TESS backend server at ${config.apiBaseUrl}.',
      );
    } on TimeoutException {
      _log('POST (Bytes)', uri, error: 'Timeout after ${config.timeout.inSeconds}s');
      throw ApiException(
        statusCode: 408,
        message: 'Request timed out after ${config.timeout.inSeconds} seconds.',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      _log('POST (Bytes)', uri, error: e.toString());
      throw ApiException(statusCode: 500, message: e.toString());
    }
  }
}
