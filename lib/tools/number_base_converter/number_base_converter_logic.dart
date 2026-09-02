const maxNumberBaseInputLength = 4096;
const supportedRadices = <int>[2, 8, 10, 16];

class NumberBaseResult {
  const NumberBaseResult({this.values = const {}, this.error});

  final Map<int, String> values;
  final String? error;
  bool get isSuccess => error == null;
}

/// 使用 BigInt 转换，避免大整数在 64 位边界处静默溢出。
NumberBaseResult convertNumberBase(String input, int sourceRadix) {
  if (!supportedRadices.contains(sourceRadix)) {
    return const NumberBaseResult(error: '不支持的源进制');
  }
  var normalized = input.trim();
  if (normalized.isEmpty) return const NumberBaseResult(error: '请输入数值');
  if (normalized.length > maxNumberBaseInputLength) {
    return const NumberBaseResult(error: '数值不能超过 4096 个字符');
  }

  var sign = '';
  if (normalized.startsWith('-') || normalized.startsWith('+')) {
    sign = normalized[0];
    normalized = normalized.substring(1);
  }
  final prefix = switch (sourceRadix) {
    2 => '0b',
    8 => '0o',
    16 => '0x',
    _ => '',
  };
  if (prefix.isNotEmpty && normalized.toLowerCase().startsWith(prefix)) {
    normalized = normalized.substring(2);
  }
  if (normalized.isEmpty) return const NumberBaseResult(error: '请输入有效数值');

  try {
    final value = BigInt.parse('$sign$normalized', radix: sourceRadix);
    return NumberBaseResult(
      values: {
        for (final radix in supportedRadices)
          radix: value.toRadixString(radix).toUpperCase(),
      },
    );
  } on FormatException {
    return NumberBaseResult(error: '输入不是有效的 $sourceRadix 进制数');
  }
}
