String apiBaseUrl(String domain, String basePath, String path, { Map<String, String>? query }) {
  final base = domain.endsWith('/') ? domain.substring(0, domain.length - 1) : domain;
  final pathClean = basePath.startsWith('/') ? basePath : '/$basePath';
  final pathEnd = path.startsWith('/') ? path.substring(1) : path;
  final queryString = query != null ? '?${query.entries.map((e) => '${e.key}=${e.value}').join('&')}' : '';
  return '$base$pathClean/$pathEnd$queryString';
}
