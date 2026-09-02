import 'dart:convert';

const maxBase64InputLength = 100000;

enum Base64ToolMode { encode, decode }

class Base64ToolResult {
  const Base64ToolResult({this.output = '', this.error});

  final String output;
  final String? error;
  bool get isSuccess => error == null;
}

/// 对 UTF-8 文本进行 Base64 转换；不把输入当作路径、脚本或二进制文件处理。
Base64ToolResult processBase64(String input, Base64ToolMode mode) {
  if (input.isEmpty) return const Base64ToolResult(error: '请输入内容');
  if (input.length > maxBase64InputLength) {
    return const Base64ToolResult(error: '内容不能超过 100000 个字符');
  }
  try {
    return switch (mode) {
      Base64ToolMode.encode => Base64ToolResult(
        output: base64Encode(utf8.encode(input)),
      ),
      Base64ToolMode.decode => Base64ToolResult(
        output: utf8.decode(base64Decode(input.replaceAll(RegExp(r'\s+'), ''))),
      ),
    };
  } on FormatException {
    return const Base64ToolResult(error: 'Base64 或 UTF-8 文本格式无效');
  }
}
