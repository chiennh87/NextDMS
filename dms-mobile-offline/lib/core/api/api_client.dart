import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// HTTP API client with token injection and timeout.
class ApiClient {
  final String baseUrl;
  final Duration timeout;
  String? _accessToken;
  final http.Client _client;

  ApiClient({required this.baseUrl, this.timeout = const Duration(seconds: 15), http.Client? client})
      : _client = client ?? http.Client();

  void setAccessToken(String? token) {
    _accessToken = token;
  }

  Map<String, String> _headers(Map<String, String>? extra) {
    final h = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_accessToken != null) h['Authorization'] = 'Bearer $_accessToken';
    if (extra != null) h.addAll(extra);
    return h;
  }

  Uri _uri(String path) {
    if (path.startsWith('http')) return Uri.parse(path);
    final sep = path.startsWith('/') ? '' : '/';
    return Uri.parse('$baseUrl$sep$path');
  }

  Future<dynamic> get(String path, {Map<String, String>? headers, Map<String, String>? query}) async {
    final uri = _uri(path);
    final qp = (query == null || query.isEmpty) ? uri : uri.replace(queryParameters: {...uri.queryParameters, ...query});
    final res = await _client.get(qp, headers: _headers(headers)).timeout(timeout);
    return _parse(res);
  }

  Future<dynamic> post(String path, {dynamic body, Map<String, String>? headers}) async {
    final res = await _client
        .post(_uri(path), headers: _headers(headers), body: body == null ? null : jsonEncode(body))
        .timeout(timeout);
    return _parse(res);
  }

  Future<dynamic> put(String path, {dynamic body, Map<String, String>? headers}) async {
    final res = await _client
        .put(_uri(path), headers: _headers(headers), body: body == null ? null : jsonEncode(body))
        .timeout(timeout);
    return _parse(res);
  }

  Future<dynamic> delete(String path, {Map<String, String>? headers}) async {
    final res = await _client.delete(_uri(path), headers: _headers(headers)).timeout(timeout);
    return _parse(res);
  }

  dynamic _parse(http.Response res) {
    final code = res.statusCode;
    final body = res.body;
    if (code >= 200 && code < 300) {
      if (body.isEmpty) return <String, dynamic>{};
      try {
        return jsonDecode(body);
      } catch (_) {
        return body;
      }
    }
    String msg = 'HTTP $code';
    try {
      final j = jsonDecode(body);
      if (j is Map && j['message'] != null) msg = j['message'].toString();
      else if (j is Map && j['error'] != null) msg = j['error'].toString();
    } catch (_) {}
    throw ApiException(code, msg);
  }

  void close() => _client.close();
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);
  @override
  String toString() => 'ApiException($statusCode): $message';
}
