import 'dart:convert';

const maxJwtInputLength = 100000;

class JwtViewerResult {
  const JwtViewerResult({
    this.header = const {},
    this.payload = const {},
    this.headerText = '',
    this.payloadText = '',
    this.expiryStatus = '',
    this.error,
  });

  final Map<String, Object?> header;
  final Map<String, Object?> payload;
  final String headerText;
  final String payloadText;
  final String expiryStatus;
  final String? error;
  bool get isSuccess => error == null;
}

/// 只查看 JWT 紧凑格式中的 JSON，不校验签名，也不应据此信任任何声明。
JwtViewerResult parseJwtForViewing(String input, {DateTime? now}) {
  final token = input.trim();
  if (token.isEmpty) return const JwtViewerResult(error: '请输入 JWT 令牌');
  if (token.length > maxJwtInputLength) {
    return const JwtViewerResult(error: '令牌不能超过 100000 个字符');
  }
  final segments = token.split('.');
  if (segments.length != 3 || segments[0].isEmpty || segments[1].isEmpty) {
    return const JwtViewerResult(error: 'JWT 应包含头部、载荷和签名三段');
  }

  try {
    final header = _decodeJsonObject(segments[0]);
    final payload = _decodeJsonObject(segments[1]);
    const encoder = JsonEncoder.withIndent('  ');
    return JwtViewerResult(
      header: header,
      payload: payload,
      headerText: encoder.convert(header),
      payloadText: encoder.convert(payload),
      expiryStatus: _expiryStatus(payload['exp'], now ?? DateTime.now()),
    );
  } on FormatException {
    return const JwtViewerResult(error: 'JWT 编码或 JSON 格式无效');
  }
}

Map<String, Object?> _decodeJsonObject(String segment) {
  final normalized = base64Url.normalize(segment);
  final decoded = utf8.decode(base64Url.decode(normalized));
  final json = jsonDecode(decoded);
  if (json is! Map<String, dynamic>) {
    throw const FormatException('JWT segment is not an object');
  }
  return Map<String, Object?>.from(json);
}

String _expiryStatus(Object? value, DateTime now) {
  if (value == null) return '未提供过期时间（exp）';
  if (value is! num || !value.isFinite) return '过期时间（exp）格式无效';
  try {
    final expiry = DateTime.fromMillisecondsSinceEpoch(
      (value * 1000).round(),
      isUtc: true,
    );
    return expiry.isAfter(now.toUtc()) ? '未过期（未验证）' : '已过期';
  } on RangeError {
    return '过期时间（exp）超出范围';
  }
}
