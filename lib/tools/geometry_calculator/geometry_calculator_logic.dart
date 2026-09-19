import 'dart:math' as math;

const minGeometryLength = 1e-9;
const maxGeometryLength = 1e9;
const maxGeometryInputLength = 32;

enum GeometryShape { rectangle, circle, triangle }

extension GeometryShapeInfo on GeometryShape {
  String get label => switch (this) {
    GeometryShape.rectangle => '矩形',
    GeometryShape.circle => '圆形',
    GeometryShape.triangle => '三角形',
  };
  List<String> get fields => switch (this) {
    GeometryShape.rectangle => const ['长度', '宽度'],
    GeometryShape.circle => const ['半径'],
    GeometryShape.triangle => const ['边长 a', '边长 b', '边长 c'],
  };
  String get areaFormula => switch (this) {
    GeometryShape.rectangle => '面积 = 长 × 宽',
    GeometryShape.circle => '面积 = π × 半径²',
    GeometryShape.triangle => '面积 = √[s(s−a)(s−b)(s−c)]，s = 周长 ÷ 2',
  };
  String get perimeterFormula => switch (this) {
    GeometryShape.rectangle => '周长 = 2 × (长 + 宽)',
    GeometryShape.circle => '周长 = 2 × π × 半径',
    GeometryShape.triangle => '周长 = a + b + c',
  };
}

class GeometryResult {
  const GeometryResult({required this.area, required this.perimeter});
  final double area;
  final double perimeter;
}

/// 用户必须统一长度单位；该工具只计算数字，不读取或测量图片。
GeometryResult calculateGeometry(GeometryShape shape, List<String> inputs) {
  if (inputs.length != shape.fields.length) {
    throw const FormatException('长度数量与所选形状不匹配');
  }
  final values = inputs.map(_length).toList();
  late final double area;
  late final double perimeter;
  switch (shape) {
    case GeometryShape.rectangle:
      area = values[0] * values[1];
      perimeter = 2 * (values[0] + values[1]);
    case GeometryShape.circle:
      area = math.pi * values[0] * values[0];
      perimeter = 2 * math.pi * values[0];
    case GeometryShape.triangle:
      final sorted = List<double>.of(values)..sort((a, b) => b.compareTo(a));
      final a = sorted[0], b = sorted[1], c = sorted[2];
      final difference = a - b;
      if (c <= difference) {
        throw const FormatException('三边不能构成有效三角形');
      }
      // Kahan 重排海伦公式，降低细长三角形中的相减消差。
      final product =
          (a + (b + c)) * (c - difference) * (c + difference) * (a + (b - c));
      area = math.sqrt(product) / 4;
      perimeter = a + b + c;
  }
  if (!area.isFinite || !perimeter.isFinite || area <= 0) {
    throw const FormatException('结果超出可表示范围');
  }
  return GeometryResult(area: area, perimeter: perimeter);
}

double _length(String input) {
  if (input.length > maxGeometryInputLength) {
    throw const FormatException('每项长度不能超过 32 个字符');
  }
  final value = double.tryParse(input.trim());
  if (value == null ||
      !value.isFinite ||
      value < minGeometryLength ||
      value > maxGeometryLength) {
    throw const FormatException('长度必须在 1e-9–1e9 范围内');
  }
  return value;
}

String formatGeometryNumber(double value) {
  if (value.abs() >= 1e12 || value.abs() < 1e-6) {
    return value.toStringAsExponential(8);
  }
  return value
      .toStringAsFixed(8)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}
