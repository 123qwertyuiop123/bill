const maxUrlToolInputLength = 100000;

enum UrlToolMode { encode, decode, query }

class UrlQueryEntry {
  const UrlQueryEntry({required this.key, required this.values});

  final String key;
  final List<String> values;
}

class UrlToolResult {
  const UrlToolResult({
    this.output = '',
    this.queryEntries = const [],
    this.error,
  });

  final String output;
  final List<UrlQueryEntry> queryEntries;
  final String? error;
  bool get isSuccess => error == null;
}

/// 仅按 URI 组件规则处理文本，不访问输入的网址，也不会触发网络请求。
UrlToolResult processUrlText(String input, UrlToolMode mode) {
  if (input.isEmpty) return const UrlToolResult(error: '请输入内容');
  if (input.length > maxUrlToolInputLength) {
    return const UrlToolResult(error: '内容不能超过 100000 个字符');
  }

  try {
    return switch (mode) {
      UrlToolMode.encode => UrlToolResult(output: Uri.encodeComponent(input)),
      UrlToolMode.decode => UrlToolResult(output: Uri.decodeComponent(input)),
      UrlToolMode.query => _parseQuery(input),
    };
  } on ArgumentError {
    return const UrlToolResult(error: 'URL 编码格式无效');
  }
}

UrlToolResult _parseQuery(String input) {
  // 同时兼容完整 URL、以 ? 开头的查询串以及直接输入的 a=1&b=2。
  final questionMark = input.indexOf('?');
  var query = questionMark >= 0 ? input.substring(questionMark + 1) : input;
  final fragmentMark = query.indexOf('#');
  if (fragmentMark >= 0) query = query.substring(0, fragmentMark);
  if (query.isEmpty) return const UrlToolResult(error: '没有可解析的查询参数');

  final grouped = <String, List<String>>{};
  for (final pair in query.split('&')) {
    if (pair.isEmpty) continue;
    final equalsMark = pair.indexOf('=');
    final rawKey = equalsMark < 0 ? pair : pair.substring(0, equalsMark);
    final rawValue = equalsMark < 0 ? '' : pair.substring(equalsMark + 1);
    final key = _decodeQueryComponent(rawKey);
    final value = _decodeQueryComponent(rawValue);
    grouped.putIfAbsent(key, () => <String>[]).add(value);
  }
  if (grouped.isEmpty) return const UrlToolResult(error: '没有可解析的查询参数');

  final entries = grouped.entries
      .map((entry) => UrlQueryEntry(key: entry.key, values: entry.value))
      .toList(growable: false);
  final output = entries
      .map((entry) => '${entry.key}: ${entry.values.join(', ')}')
      .join('\n');
  return UrlToolResult(output: output, queryEntries: entries);
}

String _decodeQueryComponent(String value) {
  // 文件管理器或浏览器复制出的 URL 可能含有未转义中文：先保护字面字符，
  // 再恢复原有百分号并解码，可兼容中文且仍会拒绝 %ZZ 等损坏序列。
  final protected = Uri.encodeQueryComponent(value.replaceAll('+', ' '))
      .replaceAll('%25', '%');
  return Uri.decodeQueryComponent(protected);
}
