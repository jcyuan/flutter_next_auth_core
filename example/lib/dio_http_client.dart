import 'package:dio/dio.dart';
import 'package:flutter_next_auth/next_auth.dart';

/// Minimal [HttpClient] implementation using Dio.
///
/// This is for the example app only — you can copy it into your own project
/// and extend it as needed (timeouts, interceptors, etc).
class DioHttpClient implements HttpClient {
  final Dio _dio;

  DioHttpClient([Dio? dio]) : _dio = dio ?? Dio();

  @override
  Future<HttpResponse> get(String url, {HttpClientOptions? options}) async {
    final res = await _dio.get(
      url,
      options: Options(
        contentType: options?.contentType,
        headers: _buildHeaders(options),
        followRedirects: options?.followRedirects,
        validateStatus: options?.validateStatus == null
            ? null
            : (s) => options!.validateStatus!(s),
        responseType: _mapResponseType(options?.responseType),
      ),
    );

    return HttpResponse(
      statusCode: res.statusCode,
      body: res.data,
      headers: _toHeaderMap(res.headers.map),
    );
  }

  @override
  Future<HttpResponse> post(
    String url, {
    HttpClientOptions? options,
    Object? body,
  }) async {
    final res = await _dio.post(
      url,
      data: body ?? options?.body,
      options: Options(
        contentType: options?.contentType,
        headers: _buildHeaders(options),
        followRedirects: options?.followRedirects,
        validateStatus: options?.validateStatus == null
            ? null
            : (s) => options!.validateStatus!(s),
        responseType: _mapResponseType(options?.responseType),
      ),
    );

    return HttpResponse(
      statusCode: res.statusCode,
      body: res.data,
      headers: _toHeaderMap(res.headers.map),
    );
  }

  Map<String, dynamic> _buildHeaders(HttpClientOptions? options) {
    final headers = <String, dynamic>{...?options?.headers};
    final cookies = options?.cookies;
    if (cookies != null && cookies.isNotEmpty) {
      headers['cookie'] =
          cookies.entries.map((e) => '${e.key}=${e.value}').join('; ');
    }
    return headers;
  }

  ResponseType? _mapResponseType(HttpClientResponseType? type) {
    if (type == null) return null;
    return switch (type) {
      HttpClientResponseType.json => ResponseType.json,
      HttpClientResponseType.plain => ResponseType.plain,
      HttpClientResponseType.bytes => ResponseType.bytes,
      HttpClientResponseType.stream => ResponseType.stream,
    };
  }

  Map<String, List<String>> _toHeaderMap(Map<String, List<String>> dioHeaders) {
    return dioHeaders.map((k, v) => MapEntry(k.toLowerCase(), v));
  }
}

