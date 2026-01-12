class HttpResponse {
  final int? statusCode;
  final dynamic body;
  final Map<String, List<String>> headers;

  HttpResponse({
    required this.statusCode,
    this.body,
    required this.headers,
  });
}

