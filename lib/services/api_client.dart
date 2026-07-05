import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:http/http.dart' as http;
import 'package:memo_places_mobile/config/app_config.dart';
import 'package:memo_places_mobile/services/api_exception.dart';
import 'package:memo_places_mobile/services/auth_service.dart';
import 'package:memo_places_mobile/translations/locale_keys.g.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// The one way to talk to the backend: base url from [AppConfig], bearer
/// token when signed in, 15 s timeout, 2xx success, typed localized errors.
class ApiClient {
  static const _timeout = Duration(seconds: 15);

  final AuthService _auth;
  final http.Client _inner;
  final Future<void> Function()? _onUnauthorized;
  final void Function(Breadcrumb) _addBreadcrumb;

  ApiClient(
    this._auth, {
    http.Client? inner,
    Future<void> Function()? onUnauthorized,
    void Function(Breadcrumb)? addBreadcrumb,
  })  : _inner = inner ?? http.Client(),
        _onUnauthorized = onUnauthorized,
        _addBreadcrumb = addBreadcrumb ?? Sentry.addBreadcrumb,
        assert(
          isBaseUrlAllowed(AppConfig.apiBaseUrl, isProd: AppConfig.isProd),
          'Production builds must talk to the API over HTTPS; '
          'got "${AppConfig.apiBaseUrl}". Fix API_BASE_URL in env/prod.json.',
        );

  /// Production builds may only talk to the backend over HTTPS; plain http
  /// is allowed in dev so the emulator can reach a local backend.
  static bool isBaseUrlAllowed(String baseUrl, {required bool isProd}) =>
      !isProd || baseUrl.startsWith('https://');

  Future<dynamic> get(String path) => _send('GET', path);

  Future<dynamic> post(String path, {Object? body}) =>
      _send('POST', path, body: body);

  Future<dynamic> put(String path, {Object? body}) =>
      _send('PUT', path, body: body);

  Future<dynamic> patch(String path, {Object? body}) =>
      _send('PATCH', path, body: body);

  Future<void> delete(String path) => _send('DELETE', path);

  /// Uploads [file] as multipart/form-data under [fileField]. The backend
  /// image endpoints take exactly one file per request.
  Future<dynamic> multipart(
    String path,
    Map<String, String> fields,
    File file, {
    String fileField = 'file',
  }) async {
    final request =
        http.MultipartRequest('POST', Uri.parse(AppConfig.apiBaseUrl + path));
    request.fields.addAll(fields);
    request.files.add(await http.MultipartFile.fromPath(fileField, file.path));

    final token = await _auth.currentAccessToken();
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    try {
      final streamed = await _inner.send(request).timeout(_timeout);
      final response = await http.Response.fromStream(streamed);
      _recordBreadcrumb('POST', request.url, response.statusCode);
      return _handleResponse(response);
    } on SocketException {
      throw ApiException(LocaleKeys.no_connection_error.tr());
    } on TimeoutException {
      throw ApiException(LocaleKeys.no_connection_error.tr());
    } on http.ClientException {
      throw ApiException(LocaleKeys.no_connection_error.tr());
    }
  }

  /// Crash-report context: method, url and status only — never request or
  /// response bodies, and never headers (the bearer token lives there).
  void _recordBreadcrumb(String method, Uri url, int statusCode) {
    _addBreadcrumb(
        Breadcrumb.http(url: url, method: method, statusCode: statusCode));
  }

  Future<dynamic> _send(String method, String path, {Object? body}) async {
    final request = http.Request(method, Uri.parse(AppConfig.apiBaseUrl + path));
    request.headers['Content-Type'] = 'application/json';

    final token = await _auth.currentAccessToken();
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    if (body != null) {
      request.body = jsonEncode(body);
    }

    try {
      final streamed = await _inner.send(request).timeout(_timeout);
      final response = await http.Response.fromStream(streamed);
      _recordBreadcrumb(method, request.url, response.statusCode);
      return _handleResponse(response);
    } on SocketException {
      throw ApiException(LocaleKeys.no_connection_error.tr());
    } on TimeoutException {
      throw ApiException(LocaleKeys.no_connection_error.tr());
    } on http.ClientException {
      throw ApiException(LocaleKeys.no_connection_error.tr());
    }
  }

  Future<dynamic> _handleResponse(http.Response response) async {
    final status = response.statusCode;

    if (status >= 200 && status < 300) {
      if (response.bodyBytes.isEmpty) return null;
      return jsonDecode(utf8.decode(response.bodyBytes));
    }

    if (status == 401) {
      await _onUnauthorized?.call();
      throw ApiException(LocaleKeys.session_expired.tr(), 401);
    }

    throw ApiException(_problemMessage(response), status);
  }

  /// RFC 7807 problem-details bodies carry the most specific message the
  /// backend has; fall back to a generic localized error otherwise.
  String _problemMessage(http.Response response) {
    try {
      final problem = jsonDecode(utf8.decode(response.bodyBytes));
      if (problem is Map<String, dynamic>) {
        final errors = problem['errors'];
        if (errors is Map<String, dynamic>) {
          for (final value in errors.values) {
            if (value is List && value.isNotEmpty) {
              return value.first.toString();
            }
          }
        }
        final detail = problem['detail'] ?? problem['title'];
        if (detail is String && detail.isNotEmpty) return detail;
        final error = problem['error'];
        if (error is String && error.isNotEmpty) return error;
      }
    } on FormatException {
      // Non-JSON error body — use the generic message.
    }
    return LocaleKeys.alert_error.tr();
  }
}
