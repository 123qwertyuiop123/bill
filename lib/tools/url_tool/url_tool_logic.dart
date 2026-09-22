const maxUrlToolInputLength = 100000;
const maxDomainInputLength = 512;
const maxAsciiDomainLength = 253;

final _unsafeDomainCharacterPattern = RegExp(r'[\p{Cc}\p{Cf}]', unicode: true);

enum UrlToolMode { encode, decode, query, domain }

enum DomainConversionDirection { unicodeToAscii, asciiToUnicode }

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
UrlToolResult processUrlText(
  String input,
  UrlToolMode mode, {
  DomainConversionDirection domainDirection =
      DomainConversionDirection.unicodeToAscii,
}) {
  if (input.isEmpty) return const UrlToolResult(error: '请输入内容');
  if (mode == UrlToolMode.domain) {
    return convertInternationalDomain(input, domainDirection);
  }
  if (input.length > maxUrlToolInputLength) {
    return const UrlToolResult(error: '内容不能超过 100000 个字符');
  }

  try {
    return switch (mode) {
      UrlToolMode.encode => UrlToolResult(output: Uri.encodeComponent(input)),
      UrlToolMode.decode => UrlToolResult(output: Uri.decodeComponent(input)),
      UrlToolMode.query => _parseQuery(input),
      UrlToolMode.domain => throw StateError('已单独处理国际化域名'),
    };
  } on ArgumentError {
    return const UrlToolResult(error: 'URL 编码格式无效');
  }
}

/// 在本机完成 RFC 3492 Punycode 转换；这不是完整的 IDNA 注册有效性检查。
UrlToolResult convertInternationalDomain(
  String input,
  DomainConversionDirection direction,
) {
  final domain = input.trim().replaceAll(RegExp('[。．｡]'), '.');
  if (domain.isEmpty) return const UrlToolResult(error: '请输入域名');
  if (input.length > maxDomainInputLength) {
    return const UrlToolResult(error: '域名内容不能超过 512 个字符');
  }
  // 控制字符、零宽字符和双向格式字符会造成不可见或重排显示的域名文本。
  if (_unsafeDomainCharacterPattern.hasMatch(domain)) {
    return const UrlToolResult(error: '域名不能包含控制字符或不可见格式字符');
  }
  if (RegExp(r'\s').hasMatch(domain) ||
      domain.contains(RegExp(r'[:/@\\?#\[\]]'))) {
    return const UrlToolResult(error: '只支持域名，不要输入协议、端口、账号或路径');
  }

  try {
    final labels = domain.split('.');
    if (labels.any((label) => label.isEmpty)) {
      return const UrlToolResult(error: '域名标签不能为空');
    }
    final converted = labels
        .map((label) {
          if (label.startsWith('-') || label.endsWith('-')) {
            throw const FormatException('域名标签不能以连字符开头或结尾');
          }
          return direction == DomainConversionDirection.unicodeToAscii
              ? _encodeDomainLabel(label)
              : _decodeDomainLabel(label);
        })
        .toList(growable: false);
    final output = converted.join('.');
    final ascii = direction == DomainConversionDirection.unicodeToAscii
        ? output
        : labels.join('.');
    if (ascii.length > maxAsciiDomainLength) {
      return const UrlToolResult(error: 'ASCII 域名不能超过 253 个字符');
    }
    return UrlToolResult(output: output);
  } on FormatException catch (error) {
    return UrlToolResult(error: error.message);
  }
}

String _encodeDomainLabel(String label) {
  final normalized = label.toLowerCase();
  final isAscii = normalized.runes.every((rune) => rune < 0x80);
  if (isAscii) {
    _validateAsciiLabel(normalized);
    return normalized;
  }
  if (_unsafeDomainCharacterPattern.hasMatch(normalized)) {
    throw const FormatException('域名不能包含控制字符或不可见格式字符');
  }
  final encoded = 'xn--${_punycodeEncode(normalized)}';
  _validateAsciiLabel(encoded);
  return encoded;
}

String _decodeDomainLabel(String label) {
  final normalized = label.toLowerCase();
  _validateAsciiLabel(normalized);
  if (!normalized.startsWith('xn--')) return normalized;
  final payload = normalized.substring(4);
  if (payload.isEmpty) throw const FormatException('Punycode 标签不完整');
  final decoded = _punycodeDecode(payload);
  if (_unsafeDomainCharacterPattern.hasMatch(decoded)) {
    throw const FormatException('Punycode 解码结果包含控制字符或不可见格式字符');
  }
  // 重新编码可拒绝非规范或被截断的 ACE 标签。
  if (_encodeDomainLabel(decoded) != normalized) {
    throw const FormatException('Punycode 标签不是规范格式');
  }
  return decoded;
}

void _validateAsciiLabel(String label) {
  if (label.isEmpty || label.length > 63) {
    throw const FormatException('每个域名标签必须为 1–63 个 ASCII 字符');
  }
  if (!RegExp(r'^[a-z0-9-]+$').hasMatch(label)) {
    throw const FormatException('ASCII 域名只能包含字母、数字和连字符');
  }
  if (label.startsWith('-') || label.endsWith('-')) {
    throw const FormatException('域名标签不能以连字符开头或结尾');
  }
}

const _punycodeBase = 36;
const _punycodeTMin = 1;
const _punycodeTMax = 26;
const _punycodeSkew = 38;
const _punycodeDamp = 700;
const _punycodeInitialBias = 72;
const _punycodeInitialN = 128;

String _punycodeEncode(String input) {
  final codePoints = input.runes.toList(growable: false);
  final output = StringBuffer();
  for (final codePoint in codePoints) {
    if (codePoint < 0x80) output.writeCharCode(codePoint);
  }
  final basicCount = output.length;
  var handled = basicCount;
  if (basicCount > 0) output.write('-');

  var n = _punycodeInitialN;
  var delta = 0;
  var bias = _punycodeInitialBias;
  while (handled < codePoints.length) {
    var next = 0x110000;
    for (final codePoint in codePoints) {
      if (codePoint >= n && codePoint < next) next = codePoint;
    }
    if (next == 0x110000) throw const FormatException('Punycode 编码失败');
    delta = _checkedAdd(delta, (next - n) * (handled + 1));
    n = next;
    for (final codePoint in codePoints) {
      if (codePoint < n) delta = _checkedAdd(delta, 1);
      if (codePoint != n) continue;
      var q = delta;
      for (var k = _punycodeBase; ; k += _punycodeBase) {
        final threshold = k <= bias
            ? _punycodeTMin
            : k >= bias + _punycodeTMax
            ? _punycodeTMax
            : k - bias;
        if (q < threshold) break;
        output.write(
          _punycodeDigit(
            threshold + (q - threshold) % (_punycodeBase - threshold),
          ),
        );
        q = (q - threshold) ~/ (_punycodeBase - threshold);
      }
      output.write(_punycodeDigit(q));
      bias = _adaptPunycodeBias(delta, handled + 1, handled == basicCount);
      delta = 0;
      handled += 1;
    }
    delta = _checkedAdd(delta, 1);
    n += 1;
  }
  return output.toString();
}

String _punycodeDecode(String input) {
  if (!RegExp(r'^[a-z0-9-]+$').hasMatch(input)) {
    throw const FormatException('Punycode 标签包含无效字符');
  }
  final output = <int>[];
  final delimiter = input.lastIndexOf('-');
  var index = 0;
  if (delimiter >= 0) {
    for (final rune in input.substring(0, delimiter).runes) {
      if (rune >= 0x80) throw const FormatException('Punycode 基础字符无效');
      output.add(rune);
    }
    index = delimiter + 1;
  }

  var n = _punycodeInitialN;
  var i = 0;
  var bias = _punycodeInitialBias;
  while (index < input.length) {
    final oldI = i;
    var weight = 1;
    for (var k = _punycodeBase; ; k += _punycodeBase) {
      if (index >= input.length) throw const FormatException('Punycode 标签被截断');
      final digit = _decodePunycodeDigit(input.codeUnitAt(index++));
      i = _checkedAdd(i, digit * weight);
      final threshold = k <= bias
          ? _punycodeTMin
          : k >= bias + _punycodeTMax
          ? _punycodeTMax
          : k - bias;
      if (digit < threshold) break;
      weight = _checkedMultiply(weight, _punycodeBase - threshold);
    }
    final outputLength = output.length + 1;
    bias = _adaptPunycodeBias(i - oldI, outputLength, oldI == 0);
    n = _checkedAdd(n, i ~/ outputLength);
    i %= outputLength;
    if (n > 0x10ffff || (n >= 0xd800 && n <= 0xdfff)) {
      throw const FormatException('Punycode 码点无效');
    }
    output.insert(i, n);
    i += 1;
  }
  return String.fromCharCodes(output);
}

int _adaptPunycodeBias(int delta, int pointCount, bool firstTime) {
  delta = firstTime ? delta ~/ _punycodeDamp : delta ~/ 2;
  delta += delta ~/ pointCount;
  var k = 0;
  final limit = ((_punycodeBase - _punycodeTMin) * _punycodeTMax) ~/ 2;
  while (delta > limit) {
    delta ~/= _punycodeBase - _punycodeTMin;
    k += _punycodeBase;
  }
  return k +
      (((_punycodeBase - _punycodeTMin + 1) * delta) ~/
          (delta + _punycodeSkew));
}

String _punycodeDigit(int digit) {
  if (digit < 0 || digit >= _punycodeBase) {
    throw const FormatException('Punycode 数字无效');
  }
  return String.fromCharCode(digit < 26 ? 97 + digit : 22 + digit);
}

int _decodePunycodeDigit(int codeUnit) {
  if (codeUnit >= 97 && codeUnit <= 122) return codeUnit - 97;
  if (codeUnit >= 48 && codeUnit <= 57) return codeUnit - 22;
  throw const FormatException('Punycode 字符无效');
}

int _checkedAdd(int first, int second) {
  const limit = 0x1fffffffffffff;
  if (first < 0 || second < 0 || first > limit - second) {
    throw const FormatException('Punycode 数值超出安全范围');
  }
  return first + second;
}

int _checkedMultiply(int first, int second) {
  const limit = 0x1fffffffffffff;
  if (first < 0 || second < 0 || (first != 0 && second > limit ~/ first)) {
    throw const FormatException('Punycode 数值超出安全范围');
  }
  return first * second;
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
