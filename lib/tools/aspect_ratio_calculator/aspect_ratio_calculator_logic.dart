const maxAspectDimension = 100000;

class AspectRatioResult {
  const AspectRatioResult({
    required this.width,
    required this.height,
    required this.ratioWidth,
    required this.ratioHeight,
  });

  final int width;
  final int height;
  final int ratioWidth;
  final int ratioHeight;

  double get decimal => width / height;

  String get orientation => switch (width.compareTo(height)) {
    > 0 => '横向',
    < 0 => '纵向',
    _ => '正方形',
  };

  String get ratioLabel => '$ratioWidth : $ratioHeight';

  int heightForWidth(int targetWidth) {
    _validateDimension(targetWidth);
    final value = (targetWidth * height / width).round();
    _validateDimension(value);
    return value;
  }

  int widthForHeight(int targetHeight) {
    _validateDimension(targetHeight);
    final value = (targetHeight * width / height).round();
    _validateDimension(value);
    return value;
  }
}

/// 将宽高约分为最简整数比例，避免用浮点近似值作为比例来源。
AspectRatioResult calculateAspectRatio(String widthText, String heightText) {
  final width = _parseDimension(widthText, '宽度');
  final height = _parseDimension(heightText, '高度');
  final divisor = _greatestCommonDivisor(width, height);
  return AspectRatioResult(
    width: width,
    height: height,
    ratioWidth: width ~/ divisor,
    ratioHeight: height ~/ divisor,
  );
}

int _parseDimension(String input, String label) {
  final value = int.tryParse(input.trim());
  if (value == null) throw FormatException('请输入有效的$label整数');
  try {
    _validateDimension(value);
  } on RangeError {
    throw FormatException('$label必须在 1–$maxAspectDimension 之间');
  }
  return value;
}

void _validateDimension(int value) {
  if (value < 1 || value > maxAspectDimension) {
    throw RangeError.range(value, 1, maxAspectDimension);
  }
}

int _greatestCommonDivisor(int first, int second) {
  var a = first;
  var b = second;
  while (b != 0) {
    final remainder = a % b;
    a = b;
    b = remainder;
  }
  return a;
}
