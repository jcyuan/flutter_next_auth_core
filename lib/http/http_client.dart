import 'package:flutter_next_auth_core/http/http_response.dart';

/// HTTP response content type
enum HttpClientResponseType { json, stream, plain, bytes }

/// Options for HTTP client requests
class HttpClientOptions {
  /// Request cookies
  Map<String, String>? cookies;
  
  /// Request headers
  Map<String, String>? headers;
  
  /// Request body
  dynamic body;
  
  /// Whether to preserve header case
  bool? preserveHeaderCase;
  
  /// Send timeout in milliseconds
  int? sendTimeout;
  
  /// Receive timeout in milliseconds
  int? receiveTimeout;
  
  /// Content type of the request
  String? contentType;
  
  /// Function to validate response status
  Function(int? status)? validateStatus;
  
  /// Whether to follow redirects
  bool? followRedirects;
  
  /// Maximum number of redirects to follow
  int? maxRedirects;
  
  /// Expected response type
  HttpClientResponseType? responseType;

  /// Creates HTTP client options
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

/// Abstract HTTP client interface
abstract class HttpClient {
  /// Performs a GET request
  Future<HttpResponse> get(String url, {HttpClientOptions? options});
  
  /// Performs a POST request
  Future<HttpResponse> post(
    String url, {
    HttpClientOptions? options,
    Object? body,
  });
}
