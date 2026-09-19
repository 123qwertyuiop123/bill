enum LinearBarcodeType { code128, ean13, upcA }

extension LinearBarcodeTypeLabel on LinearBarcodeType {
  String get label => switch (this) {
    LinearBarcodeType.code128 => 'Code 128',
    LinearBarcodeType.ean13 => 'EAN-13',
    LinearBarcodeType.upcA => 'UPC-A',
  };
}

/// 在绘制前完成字符集、长度和校验位检查，避免依赖异常直接展示给用户。
String normalizeLinearBarcode(String input, LinearBarcodeType type) {
  if (type == LinearBarcodeType.code128) {
    if (input.isEmpty || input.length > 128) {
      throw const FormatException('Code 128 内容长度必须为 1–128 个字符');
    }
    if (input.codeUnits.any((value) => value < 0x20 || value > 0x7e)) {
      throw const FormatException('Code 128 第一版仅支持可打印 ASCII 字符');
    }
    return input;
  }

  final expected = type == LinearBarcodeType.ean13 ? 13 : 12;
  if (!RegExp(r'^[0-9]+$').hasMatch(input) ||
      (input.length != expected - 1 && input.length != expected)) {
    throw FormatException(
      '${type.label} 请输入 ${expected - 1} 位数据或 $expected 位完整数字',
    );
  }
  final payload = input.substring(0, expected - 1);
  final checkDigit = _modulo10(payload);
  if (input.length == expected && input[expected - 1] != checkDigit) {
    throw FormatException('${type.label} 校验位应为 $checkDigit');
  }
  return '$payload$checkDigit';
}

String _modulo10(String value) {
  var sum = 0;
  var remaining = value.length;
  for (final codeUnit in value.codeUnits) {
    final digit = codeUnit - 0x30;
    sum += remaining.isEven ? digit : digit * 3;
    remaining--;
  }
  return ((10 - sum % 10) % 10).toString();
}
