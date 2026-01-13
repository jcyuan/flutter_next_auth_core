/// HTTP response wrapper
class HttpResponse {
  /// HTTP status code
  final int? statusCode;
  
  /// Response body
  final dynamic body;
  
  /// Response headers
  final Map<String, List<String>> headers;

  /// Creates an HTTP response
  HttpResponse({required this.statusCode, this.body, required this.headers});
}
