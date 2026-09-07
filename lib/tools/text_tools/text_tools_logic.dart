const maxTextToolInputLength = 20000;
const maxHtmlEntityOutputLength = 120000;

enum HtmlEntityMode { encode, decode }

class TextTransformResult {
  const TextTransformResult({this.text = '', this.error});

  final String text;
  final String? error;
  bool get isSuccess => error == null;
}

/// 编码 HTML 中具有结构含义的五类字符，但不生成或渲染 HTML。
TextTransformResult encodeHtmlEntities(String input) {
  final error = _validateInput(input);
  if (error != null) return TextTransformResult(error: error);
  final output = input
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#39;');
  if (output.length > maxHtmlEntityOutputLength) {
    return const TextTransformResult(error: '转换结果过长，请减少输入内容');
  }
  return TextTransformResult(text: output);
}

/// 严格解码带分号的常用实体和数字实体；未知或非法实体保留原文。
///
/// 固定长度的匹配模式配合输入上限，避免畸形文本造成高成本回溯。
TextTransformResult decodeHtmlEntities(String input) {
  final error = _validateInput(input);
  if (error != null) return TextTransformResult(error: error);
  final entityPattern = RegExp(
    r'&(?:#x[0-9a-fA-F]{1,6}|#[0-9]{1,7}|[A-Za-z]{1,32});',
  );
  final output = input.replaceAllMapped(entityPattern, (match) {
    final entity = match.group(0)!;
    const named = <String, String>{
      '&amp;': '&',
      '&lt;': '<',
      '&gt;': '>',
      '&quot;': '"',
      '&apos;': "'",
      '&nbsp;': '\u00a0',
      '&copy;': '©',
      '&reg;': '®',
    };
    final namedValue = named[entity];
    if (namedValue != null) return namedValue;
    if (!entity.startsWith('&#')) return entity;
    final hexadecimal = entity.startsWith('&#x');
    final digits = entity.substring(hexadecimal ? 3 : 2, entity.length - 1);
    final codePoint = int.tryParse(digits, radix: hexadecimal ? 16 : 10);
    if (codePoint == null ||
        codePoint == 0 ||
        codePoint > 0x10ffff ||
        (codePoint >= 0xd800 && codePoint <= 0xdfff)) {
      return entity;
    }
    return String.fromCharCode(codePoint);
  });
  return TextTransformResult(text: output);
}

String? _validateInput(String input) {
  if (input.isEmpty) return '请输入文本';
  if (input.length > maxTextToolInputLength) return '文本不能超过 20000 个字符';
  return null;
}
