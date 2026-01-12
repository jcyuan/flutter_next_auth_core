import 'package:flutter_next_auth/http/http_response.dart';

enum HttpClientResponseType {
  json,
  stream,
  plain,
  bytes,
}

class HttpClientOptions {
  Map<String, String>? cookies;
  Map<String, String>? headers;
  dynamic body;
  bool? preserveHeaderCase;
  int? sendTimeout;
  int? receiveTimeout;
  String? contentType;
  Function(int? status)? validateStatus;
  bool? followRedirects;
  int? maxRedirects;
  HttpClientResponseType? responseType;

  HttpClientOptions({
    this.cookies,
    this.headers,
    this.body,
    this.preserveHeaderCase,
    this.sendTimeout,
    this.receiveTimeout,
    this.contentType,
    this.validateStatus,
    this.followRedirects,
    this.maxRedirects,
    this.responseType,
  });
}

abstract class HttpClient {
  Future<HttpResponse> get(String url, { HttpClientOptions? options });
  Future<HttpResponse> post(String url, { HttpClientOptions? options, Object? body });
}
