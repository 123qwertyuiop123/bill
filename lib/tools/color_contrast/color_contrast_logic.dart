import 'dart:math' as math;

import 'package:flutter/material.dart';

const maxColorInputLength = 7;

class RgbColor {
  const RgbColor(this.red, this.green, this.blue);

  final int red;
  final int green;
  final int blue;

  Color get color => Color.fromARGB(255, red, green, blue);
}

class ColorContrastResult {
  const ColorContrastResult({
    this.foreground,
    this.background,
    this.ratio,
    this.error,
  });

  final RgbColor? foreground;
  final RgbColor? background;
  final double? ratio;
  final String? error;
  bool get isSuccess => error == null;

  bool get normalAa => (ratio ?? 0) >= 4.5;
  bool get normalAaa => (ratio ?? 0) >= 7;
  bool get largeAa => (ratio ?? 0) >= 3;
  bool get largeAaa => (ratio ?? 0) >= 4.5;
}

/// 按 WCAG 的 sRGB 相对亮度公式计算对比度，不把系统主题或透明度混入结果。
ColorContrastResult checkColorContrast(String foreground, String background) {
  final foregroundColor = parseHexColor(foreground);
  final backgroundColor = parseHexColor(background);
  if (foregroundColor == null || backgroundColor == null) {
    return const ColorContrastResult(error: '请输入 #RGB 或 #RRGGBB 格式的颜色');
  }
  final first = _relativeLuminance(foregroundColor);
  final second = _relativeLuminance(backgroundColor);
  final lighter = math.max(first, second);
  final darker = math.min(first, second);
  return ColorContrastResult(
    foreground: foregroundColor,
    background: backgroundColor,
    ratio: (lighter + 0.05) / (darker + 0.05),
  );
}

RgbColor? parseHexColor(String input) {
  var value = input.trim();
  if (value.startsWith('#')) value = value.substring(1);
  if (RegExp(r'^[0-9a-fA-F]{3}$').hasMatch(value)) {
    value = value.split('').map((character) => '$character$character').join();
  }
  if (!RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(value)) return null;
  return RgbColor(
    int.parse(value.substring(0, 2), radix: 16),
    int.parse(value.substring(2, 4), radix: 16),
    int.parse(value.substring(4, 6), radix: 16),
  );
}

double _relativeLuminance(RgbColor color) {
  double channel(int value) {
    final normalized = value / 255;
    return normalized <= 0.04045
        ? normalized / 12.92
        : math.pow((normalized + 0.055) / 1.055, 2.4).toDouble();
  }

  return 0.2126 * channel(color.red) +
      0.7152 * channel(color.green) +
      0.0722 * channel(color.blue);
}
