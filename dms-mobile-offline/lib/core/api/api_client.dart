// ============================================================================
// ApiClient (HTTP client with auth + error handling)
// Updated to support multipart upload and base64 photo
// ============================================================================

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Custom exception cho API errors
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final dynamic data;

  ApiException(this.statusCode, this.message, [this.data]);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// HTTP Client với timeout, auth header injection, error handling
class ApiClient {
  final String baseUrl;
  final Duration timeout;
  String? _accessToken;

  ApiClient({
    required this.baseUrl,
    this.timeout = const Duration(seconds: 15),
  });

  /// Set access token (gọi sau khi login thành công)
  void setAccessToken(String? token) {
    _accessToken = token;
  }

  /// Lấy headers chung, tự động thêm Authorization
  Map<String, String> _getHeaders({bool needJson = true}) {
    final headers = <String, String>{};
    if (needJson) headers['Content-Type'] = 'application/json; charset=UTF-8';
    headers['Accept'] = 'application/json';
    if (_accessToken != null && _accessToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }
    return headers;
  }

  /// Build full URL từ path
  Uri _buildUri(String path, [Map<String, dynamic>? queryParams]) {
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    var uri = Uri.parse('$baseUrl/$cleanPath');
    if (queryParams != null) {
      queryParams.removeWhere((k, v) => v == null);
      if (queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: {
          ...uri.queryParameters,
          ...queryParams.map((k, v) => MapEntry(k, v.toString())),
        });
      }
    }
    return uri;
  }

  /// Xử lý response: kiểm tra status, parse JSON, throw exception nếu lỗi
  Map<String, dynamic> _handleResponse(http.Response response) {
    final body = response.body.isNotEmpty
        ? jsonDecode(utf8.decode(response.bodyBytes))
        : <String, dynamic>{};

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body is Map<String, dynamic> ? body : {'data': body};
    }

    // Trích xuất message lỗi từ backend Go (thường là {error: "...", message: "..."})
    String errorMessage = body['message'] ?? body['error'] ?? 'Lỗi không xác định';
    if (body['data'] is Map && (body['data'] as Map).isNotEmpty) {
      final errors = (body['data'] as Map).values.toList();
      if (errors.isNotEmpty) {
        errorMessage = errors.join(', ');
      }
    }
    throw ApiException(response.statusCode, errorMessage, body);
  }

  /// GET request
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParams,
  }) async {
    final uri = _buildUri(path, queryParams);
    final response = await http.get(uri, headers: _getHeaders()).timeout(timeout);
    return _handleResponse(response);
  }

  /// POST request
  Future<Map<String, dynamic>> post(
    String path, {
    Object? body,
    Map<String, dynamic>? queryParams,
  }) async {
    final uri = _buildUri(path, queryParams);
    final encoded = body != null ? jsonEncode(body) : '{}';
    final response = await http
        .post(uri, headers: _getHeaders(), body: encoded)
        .timeout(timeout);
    return _handleResponse(response);
  }

  /// PUT request
  Future<Map<String, dynamic>> put(
    String path, {
    Object? body,
  }) async {
    final uri = _buildUri(path);
    final encoded = body != null ? jsonEncode(body) : '{}';
    final response = await http
        .put(uri, headers: _getHeaders(), body: encoded)
        .timeout(timeout);
    return _handleResponse(response);
  }

  /// DELETE request
  Future<Map<String, dynamic>> delete(String path) async {
    final uri = _buildUri(path);
    final response = await http.delete(uri, headers: _getHeaders()).timeout(timeout);
    return _handleResponse(response);
  }

  /// POST request with file upload (multipart/form-data)
  /// Dùng để upload ảnh mặt tiền
  Future<Map<String, dynamic>> postMultipart(
    String path, {
    required Map<String, String> fields,
    required List<File> files,
    String fileFieldName = 'photo',
  }) async {
    final uri = _buildUri(path);
    final request = http.MultipartRequest('POST', uri);

    // Thêm headers (không bao gồm Content-Type vì Multipart tự thêm)
    final headers = _getHeaders(needJson: false);
    request.headers.addAll(headers);

    // Thêm fields
    request.fields.addAll(fields);

    // Thêm files
    for (var file in files) {
      request.files.add(await http.MultipartFile.fromPath(fileFieldName, file.path));
    }

    final streamedResponse = await request.send().timeout(timeout);
    final response = await http.Response.fromStream(streamedResponse);
    return _handleResponse(response);
  }
}