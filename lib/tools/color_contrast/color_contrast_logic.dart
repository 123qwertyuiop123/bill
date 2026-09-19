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

enum ColorVisionType { protanopia, deuteranopia, tritanopia }

extension ColorVisionTypeLabel on ColorVisionType {
  String get label => switch (this) {
    ColorVisionType.protanopia => '红色盲',
    ColorVisionType.deuteranopia => '绿色盲',
    ColorVisionType.tritanopia => '蓝色盲',
  };
}

class ColorVisionSimulationResult {
  const ColorVisionSimulationResult({
    this.originalForeground,
    this.originalBackground,
    this.simulatedForeground,
    this.simulatedBackground,
    this.error,
  });

  final RgbColor? originalForeground;
  final RgbColor? originalBackground;
  final RgbColor? simulatedForeground;
  final RgbColor? simulatedBackground;
  final String? error;
  bool get isSuccess => error == null;
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

/// 用固定的色觉缺陷矩阵预览颜色，不采集图片，也不把结果解释为医学诊断。
ColorVisionSimulationResult simulateColorVision(
  String foreground,
  String background,
  ColorVisionType type,
) {
  final foregroundColor = parseHexColor(foreground);
  final backgroundColor = parseHexColor(background);
  if (foregroundColor == null || backgroundColor == null) {
    return const ColorVisionSimulationResult(error: '请输入 #RGB 或 #RRGGBB 格式的颜色');
  }
  return ColorVisionSimulationResult(
    originalForeground: foregroundColor,
    originalBackground: backgroundColor,
    simulatedForeground: _simulateColor(foregroundColor, type),
    simulatedBackground: _simulateColor(backgroundColor, type),
  );
}

RgbColor _simulateColor(RgbColor color, ColorVisionType type) {
  final matrix = switch (type) {
    ColorVisionType.protanopia => const [
      [0.152286, 1.052583, -0.204868],
      [0.114503, 0.786281, 0.099216],
      [-0.003882, -0.048116, 1.051998],
    ],
    ColorVisionType.deuteranopia => const [
      [0.367322, 0.860646, -0.227968],
      [0.280085, 0.672501, 0.047413],
      [-0.011820, 0.042940, 0.968881],
    ],
    ColorVisionType.tritanopia => const [
      [1.255528, -0.076749, -0.178779],
      [-0.078411, 0.930809, 0.147602],
      [0.004733, 0.691367, 0.303900],
    ],
  };
  final source = [
    color.red,
    color.green,
    color.blue,
  ].map(_linearChannel).toList(growable: false);
  final transformed = List.generate(
    3,
    (row) => List.generate(
      3,
      (column) => matrix[row][column] * source[column],
    ).fold<double>(0, (sum, value) => sum + value),
  );
  return RgbColor(
    _encodedChannel(transformed[0]),
    _encodedChannel(transformed[1]),
    _encodedChannel(transformed[2]),
  );
}

double _linearChannel(int value) {
  final normalized = value / 255;
  return normalized <= 0.04045
      ? normalized / 12.92
      : math.pow((normalized + 0.055) / 1.055, 2.4).toDouble();
}

int _encodedChannel(double value) {
  final bounded = value.clamp(0.0, 1.0);
  final encoded = bounded <= 0.0031308
      ? bounded * 12.92
      : 1.055 * math.pow(bounded, 1 / 2.4) - 0.055;
  return (encoded * 255).round().clamp(0, 255);
}

RgbColor? parseHexColor(String input) {
  if (input.length > maxColorInputLength) return null;
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
  return 0.2126 * _linearChannel(color.red) +
      0.7152 * _linearChannel(color.green) +
      0.0722 * _linearChannel(color.blue);
}
