const maxRegexPatternLength = 512;
const maxRegexTextLength = 20000;
const maxRegexMatches = 500;

class RegexMatchItem {
  const RegexMatchItem({
    required this.value,
    required this.start,
    required this.end,
  });

  final String value;
  final int start;
  final int end;

  Map<String, Object> toMessage() => {
    'value': value,
    'start': start,
    'end': end,
  };

  factory RegexMatchItem.fromMessage(Map<Object?, Object?> message) =>
      RegexMatchItem(
        value: message['value'] as String,
        start: message['start'] as int,
        end: message['end'] as int,
      );
}

class RegexToolResult {
  const RegexToolResult({
    this.matches = const [],
    this.isTruncated = false,
    this.error,
  });

  final List<RegexMatchItem> matches;
  final bool isTruncated;
  final String? error;
  bool get isSuccess => error == null;

  Map<String, Object?> toMessage() => {
    'matches': matches.map((item) => item.toMessage()).toList(),
    'isTruncated': isTruncated,
    'error': error,
  };

  factory RegexToolResult.fromMessage(Map<Object?, Object?> message) {
    final rawMatches = message['matches'] as List<Object?>? ?? const [];
    return RegexToolResult(
      matches: rawMatches
          .map(
            (item) =>
                RegexMatchItem.fromMessage(item! as Map<Object?, Object?>),
          )
          .toList(growable: false),
      isTruncated: message['isTruncated'] as bool? ?? false,
      error: message['error'] as String?,
    );
  }
}

/// 纯计算入口由独立 Isolate 调用；容量上限用于约束内存和结果渲染成本。
RegexToolResult runRegexMatch({
  required String pattern,
  required String text,
  required bool global,
  required bool caseSensitive,
  required bool multiLine,
}) {
  if (pattern.isEmpty) return const RegexToolResult(error: '请输入正则表达式');
  if (pattern.length > maxRegexPatternLength) {
    return const RegexToolResult(error: '正则表达式不能超过 512 个字符');
  }
  if (text.isEmpty) return const RegexToolResult(error: '请输入测试文本');
  if (text.length > maxRegexTextLength) {
    return const RegexToolResult(error: '测试文本不能超过 20000 个字符');
  }

  try {
    final expression = RegExp(
      pattern,
      caseSensitive: caseSensitive,
      multiLine: multiLine,
      unicode: true,
    );
    final iterable = global
        ? expression.allMatches(text)
        : [expression.firstMatch(text)].whereType<RegExpMatch>();
    final matches = <RegexMatchItem>[];
    var truncated = false;
    for (final match in iterable) {
      if (matches.length >= maxRegexMatches) {
        truncated = true;
        break;
      }
      matches.add(
        RegexMatchItem(
          value: match.group(0) ?? '',
          start: match.start,
          end: match.end,
        ),
      );
    }
    return RegexToolResult(matches: matches, isTruncated: truncated);
  } on FormatException {
    return const RegexToolResult(error: '正则表达式格式无效');
  }
}
