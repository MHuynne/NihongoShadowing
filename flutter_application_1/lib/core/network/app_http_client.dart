export 'package:http/http.dart' hide get, post, put, patch, delete;
import 'package:http/http.dart' as _http;
import 'dart:convert';
import 'package:flutter/foundation.dart';



const _kDefaultTimeout = Duration(seconds: 90);
const _kShortTimeout   = Duration(seconds: 30);

void _logRequest(String method, Uri url) {
  debugPrint('🌐 [API REQ] $method $url');
}

void _logResponse(String method, Uri url, _http.Response res) {
  debugPrint('✅ [API RES] $method $url -> Status: ${res.statusCode}');
}

Future<_http.Response> get(Uri url, {Map<String, String>? headers}) async {
  _logRequest('GET', url);
  final res = await _http.get(url, headers: headers).timeout(_kShortTimeout);
  _logResponse('GET', url, res);
  return res;
}

Future<_http.Response> post(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
  _logRequest('POST', url);
  final res = await _http.post(url, headers: headers, body: body, encoding: encoding).timeout(_kDefaultTimeout);
  _logResponse('POST', url, res);
  return res;
}

Future<_http.Response> put(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
  _logRequest('PUT', url);
  final res = await _http.put(url, headers: headers, body: body, encoding: encoding).timeout(_kDefaultTimeout);
  _logResponse('PUT', url, res);
  return res;
}

Future<_http.Response> patch(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
  _logRequest('PATCH', url);
  final res = await _http.patch(url, headers: headers, body: body, encoding: encoding).timeout(_kDefaultTimeout);
  _logResponse('PATCH', url, res);
  return res;
}

Future<_http.Response> delete(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
  _logRequest('DELETE', url);
  final res = await _http.delete(url, headers: headers, body: body, encoding: encoding).timeout(_kShortTimeout);
  _logResponse('DELETE', url, res);
  return res;
}
