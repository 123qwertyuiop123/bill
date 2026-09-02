import 'dart:convert';

const maxJsonInputLength = 100000;

enum JsonToolMode { format, minify, validate }

class JsonToolResult {
  const JsonToolResult({this.output = '', this.error});

  final String output;
  final String? error;
  bool get isSuccess => error == null;
}

/// 只解析数据，不执行输入中的任何代码；超长内容在解析前直接拒绝。
JsonToolResult processJson(String input, JsonToolMode mode) {
  final source = input.trim();
  if (source.isEmpty) return const JsonToolResult(error: '请输入 JSON 内容');
  if (source.length > maxJsonInputLength) {
    return const JsonToolResult(error: 'JSON 不能超过 100000 个字符');
  }
  try {
    final value = jsonDecode(source);
    return switch (mode) {
      JsonToolMode.format => JsonToolResult(
        output: const JsonEncoder.withIndent('  ').convert(value),
      ),
      JsonToolMode.minify => JsonToolResult(output: jsonEncode(value)),
      JsonToolMode.validate => const JsonToolResult(output: 'JSON 格式有效'),
    };
  } on FormatException catch (error) {
    final offset = error.offset;
    return JsonToolResult(
      error: offset == null ? 'JSON 格式无效' : 'JSON 格式无效，位置：$offset',
    );
  }
}
