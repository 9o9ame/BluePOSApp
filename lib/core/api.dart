import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const apiOrigin = 'https://bluepos.bluemarketing.com.pk';

class ApiFailure implements Exception {
  final String key;
  final String message;
  final int status;
  final Map<String, dynamic> extra;
  const ApiFailure(this.key, this.message, this.status, [this.extra = const {}]);

  @override
  String toString() => message;
}

class BlueposApi {
  BlueposApi({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  final HttpClient _client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
  final Map<String, String> _cookies = {};
  bool _csrfReady = false;
  final Map<String, Uint8List> _productImageCache = {};
  static const _cookieKey = 'bluepos_mobile_auth_cookies_v1';

  Future<void> restore() async {
    try {
      final raw = await _storage.read(key: _cookieKey);
      if (raw == null) return;
      final json = jsonDecode(raw);
      if (json is Map) {
        for (final entry in json.entries) {
          if (entry.key is String && entry.value is String) {
            _cookies[entry.key as String] = entry.value as String;
          }
        }
      }
    } catch (_) {
      _cookies.clear();
      // Invalid storage is not a valid authenticated session.
    }
  }

  Future<void> clear() async {
    _cookies.clear();
    _csrfReady = false;
    _productImageCache.clear();
    await _storage.delete(key: _cookieKey);
  }

  Future<void> close() async {
    _client.close(force: true);
  }

  Future<void> _ensureCsrf() async {
    if (_csrfReady) return;
    await _call('GET', '/sanctum/csrf-cookie', null, const {});
    _csrfReady = true;
  }

  Future<dynamic> get(String path) => request('GET', path);
  Future<dynamic> post(String path, Map<String, dynamic> body, {String? idempotencyKey}) =>
      request('POST', path, body: body, idempotencyKey: idempotencyKey);
  Future<dynamic> patch(String path, Map<String, dynamic> body) => request('PATCH', path, body: body);

  Future<dynamic> request(String method, String path,
      {Map<String, dynamic>? body, String? idempotencyKey}) async {
    if (!path.startsWith('/') || path.startsWith('//') || path.contains('://')) {
      throw const ApiFailure('INVALID_PATH', 'Invalid API path.', 0);
    }
    if (method != 'GET' && method != 'HEAD') await _ensureCsrf();
    return _call(method, path, body, {
      if (idempotencyKey != null) 'Idempotency-Key': idempotencyKey,
    });
  }

  Future<dynamic> _call(String method, String path, Map<String, dynamic>? body,
      Map<String, String> customHeaders) async {
    final uri = Uri.parse('$apiOrigin$path');
    HttpClientRequest request;
    try {
      request = await _client.openUrl(method, uri).timeout(const Duration(seconds: 20));
      request.followRedirects = false;
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.headers.set('X-Requested-With', 'XMLHttpRequest');
      request.headers.set('Origin', apiOrigin);
      request.headers.set('Referer', '$apiOrigin/');
      if (_cookies.isNotEmpty) {
        request.headers.set(HttpHeaders.cookieHeader,
            _cookies.entries.map((e) => '${e.key}=${e.value}').join('; '));
      }
      final xsrf = _cookies['XSRF-TOKEN'];
      if (xsrf != null) {
        request.headers.set('X-XSRF-TOKEN', Uri.decodeComponent(xsrf));
      }
      for (final entry in customHeaders.entries) {
        request.headers.set(entry.key, entry.value);
      }
      if (body != null) {
        request.headers.contentType = ContentType.json;
        request.add(utf8.encode(jsonEncode(body)));
      }
      final response = await request.close().timeout(const Duration(seconds: 30));
      // HttpClient parses Set-Cookie including HttpOnly cookie values.
      bool cookieChanged = false;
      for (final cookie in response.cookies) {
        if (cookie.maxAge == 0) {
          cookieChanged = _cookies.remove(cookie.name) != null || cookieChanged;
        } else {
          _cookies[cookie.name] = cookie.value;
          cookieChanged = true;
        }
      }
      if (cookieChanged) {
        await _storage.write(key: _cookieKey, value: jsonEncode(_cookies));
      }
      final raw = await utf8.decoder.bind(response).join().timeout(const Duration(seconds: 30));
      final dynamic decoded = raw.isEmpty ? <String, dynamic>{} : _decode(raw);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final payload = decoded is Map ? decoded : const {};
        final err = payload['error'];
        final details = err is Map ? Map<String, dynamic>.from(err) : <String, dynamic>{};
        final key = details.remove('key')?.toString() ?? 'REQUEST_FAILED';
        final msg = details.remove('message')?.toString() ??
            'Request failed (HTTP ${response.statusCode}).';
        throw ApiFailure(key, msg, response.statusCode, details);
      }
      return decoded;
    } on ApiFailure {
      rethrow;
    } on SocketException {
      throw const ApiFailure('NETWORK', 'Internet connection is unavailable.', 0);
    } on TimeoutException {
      throw const ApiFailure('TIMEOUT', 'The server did not respond. Please retry.', 0);
    } on HandshakeException {
      throw const ApiFailure('TLS', 'Secure connection could not be verified.', 0);
    } on HttpException {
      throw const ApiFailure('HTTP', 'Network response was interrupted.', 0);
    }
  }

  /// Authenticated same-origin product images, never remote arbitrary URLs.
  /// Image bytes stay in memory only, scoped to the current authenticated user.
  Future<Uint8List?> productImage(String path) async {
    final parsed = Uri.tryParse(path);
    if (parsed == null || parsed.hasAuthority || parsed.scheme.isNotEmpty ||
        !RegExp(r'^/api/products/[0-9A-HJKMNP-TV-Z]{26}/image$').hasMatch(parsed.path)) {
      return null;
    }
    if (_productImageCache.containsKey(path)) return _productImageCache[path];
    try {
      final request = await _client.getUrl(Uri.parse('$apiOrigin$path')).timeout(const Duration(seconds: 10));
      request.headers.set(HttpHeaders.acceptHeader, 'image/png,image/jpeg,image/webp,*/*');
      if (_cookies.isNotEmpty) request.headers.set(HttpHeaders.cookieHeader,
          _cookies.entries.map((e) => '${e.key}=${e.value}').join('; '));
      final response = await request.close().timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) { await response.drain<void>(); return null; }
      final bytes = BytesBuilder(copy: false);
      await for (final chunk in response) {
        if (bytes.length + chunk.length > 2 * 1024 * 1024) return null;
        bytes.add(chunk);
      }
      final image = bytes.takeBytes();
      if (image.isEmpty) return null;
      if (_productImageCache.length >= 80) _productImageCache.clear();
      _productImageCache[path] = image;
      return image;
    } catch (_) { return null; }
  }

  dynamic _decode(String raw) {
    try {
      return jsonDecode(raw);
    } on FormatException {
      throw const ApiFailure('INVALID_RESPONSE', 'Server returned an unexpected response.', 502);
    }
  }
}

Map<String, dynamic> objectOf(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

List<Map<String, dynamic>> recordsOf(dynamic response) {
  final data = response is Map ? response['data'] : response;
  if (data is List) return data.map(objectOf).toList();
  return [];
}

String field(dynamic value, [String fallback = '']) =>
    value == null ? fallback : value.toString();
