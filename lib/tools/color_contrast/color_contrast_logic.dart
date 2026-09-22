import 'dart:math' as math;

import 'package:flutter/material.dart';

const maxColorInputLength = 7;
const maxColorFormatInputLength = 64;

class RgbColor {
  const RgbColor(this.red, this.green, this.blue);

  final int red;
  final int green;
  final int blue;

  Color get color => Color.fromARGB(255, red, green, blue);
}

enum ColorInputFormat { hex, rgb, hsl, hsv }

extension ColorInputFormatLabel on ColorInputFormat {
  String get label => switch (this) {
    ColorInputFormat.hex => 'HEX',
    ColorInputFormat.rgb => 'RGB',
    ColorInputFormat.hsl => 'HSL',
    ColorInputFormat.hsv => 'HSV',
  };

  String get example => switch (this) {
    ColorInputFormat.hex => '#197A4A',
    ColorInputFormat.rgb => '25, 122, 74',
    ColorInputFormat.hsl => '149, 66%, 29%',
    ColorInputFormat.hsv => '149, 80%, 48%',
  };
}

class ColorFormatConversionResult {
  const ColorFormatConversionResult({
    this.color,
    this.hex,
    this.rgb,
    this.hsl,
    this.hsv,
    this.error,
  });

  final RgbColor? color;
  final String? hex;
  final String? rgb;
  final String? hsl;
  final String? hsv;
  final String? error;
  bool get isSuccess => error == null;
}

class ColorPaletteTone {
  const ColorPaletteTone({
    required this.tone,
    required this.color,
    required this.hex,
  });

  final int tone;
  final RgbColor color;
  final String hex;
}

class ColorPaletteResult {
  const ColorPaletteResult({
    this.seed,
    this.tones = const [],
    this.suggestedForeground,
    this.foregroundContrast,
    this.error,
  });

  final RgbColor? seed;
  final List<ColorPaletteTone> tones;
  final String? suggestedForeground;
  final double? foregroundContrast;
  final String? error;
  bool get isSuccess => error == null;
}

/// 以种子色的色相和饱和度生成固定的五档 HSL 明度色阶。
/// 该结果适合界面草案，不替代完整品牌色彩系统或人工无障碍审查。
ColorPaletteResult generateColorPalette(String input) {
  final seed = parseHexColor(input);
  if (seed == null) {
    return const ColorPaletteResult(error: '请输入 #RGB 或 #RRGGBB 格式的种子颜色');
  }
  final hsl = _rgbToHsl(seed);
  const toneValues = [10, 30, 50, 70, 90];
  final tones = toneValues
      .map((tone) {
        // 极暗和极亮色适度降低饱和度，避免通道过早裁切并保留层次。
        final saturationFactor = tone == 10 || tone == 90 ? 0.82 : 1.0;
        final color = _parseHsl(
          '${hsl.$1}, ${hsl.$2 * saturationFactor}%, $tone%',
        )!;
        return ColorPaletteTone(
          tone: tone,
          color: color,
          hex: _hexColor(color),
        );
      })
      .toList(growable: false);

  const black = RgbColor(0, 0, 0);
  const white = RgbColor(255, 255, 255);
  final blackRatio = _contrastRatio(seed, black);
  final whiteRatio = _contrastRatio(seed, white);
  return ColorPaletteResult(
    seed: seed,
    tones: tones,
    suggestedForeground: blackRatio >= whiteRatio ? '#000000' : '#FFFFFF',
    foregroundContrast: math.max(blackRatio, whiteRatio),
  );
}

/// 严格解析常见颜色格式并统一转换为不透明 sRGB；不接受 CSS 表达式或脚本内容。
ColorFormatConversionResult convertColorFormat(
  String input,
  ColorInputFormat format,
) {
  if (input.trim().isEmpty) {
    return const ColorFormatConversionResult(error: '请输入颜色数值');
  }
  if (input.length > maxColorFormatInputLength) {
    return const ColorFormatConversionResult(error: '颜色输入不能超过 64 个字符');
  }
  final color = switch (format) {
    ColorInputFormat.hex => parseHexColor(input),
    ColorInputFormat.rgb => _parseRgb(input),
    ColorInputFormat.hsl => _parseHsl(input),
    ColorInputFormat.hsv => _parseHsv(input),
  };
  if (color == null) {
    return ColorFormatConversionResult(
      error: switch (format) {
        ColorInputFormat.hex => '请输入 #RGB 或 #RRGGBB 格式',
        ColorInputFormat.rgb => 'RGB 应为三个 0–255 通道，例如 25, 122, 74',
        ColorInputFormat.hsl => 'HSL 应为色相 0–360 和两个 0–100% 通道',
        ColorInputFormat.hsv => 'HSV 应为色相 0–360 和两个 0–100% 通道',
      },
    );
  }
  final hsl = _rgbToHsl(color);
  final hsv = _rgbToHsv(color);
  final hex = _hexColor(color);
  return ColorFormatConversionResult(
    color: color,
    hex: hex,
    rgb: '${color.red}, ${color.green}, ${color.blue}',
    hsl:
        '${_formatChannel(hsl.$1)}°, ${_formatChannel(hsl.$2)}%, ${_formatChannel(hsl.$3)}%',
    hsv:
        '${_formatChannel(hsv.$1)}°, ${_formatChannel(hsv.$2)}%, ${_formatChannel(hsv.$3)}%',
  );
}

RgbColor? _parseRgb(String input) {
  final parts = _functionalChannelParts(input, 'rgb');
  if (parts == null) return null;
  final values = parts.map(_parseRgbChannel).toList(growable: false);
  if (values.any((value) => value == null)) return null;
  return RgbColor(values[0]!, values[1]!, values[2]!);
}

RgbColor? _parseHsl(String input) {
  final values = _parseCylindricalChannels(input, 'hsl');
  if (!_validCylindricalChannels(values)) return null;
  final hue = values![0] == 360 ? 0.0 : values[0];
  final saturation = values[1] / 100;
  final lightness = values[2] / 100;
  final chroma = (1 - (2 * lightness - 1).abs()) * saturation;
  final x = chroma * (1 - ((hue / 60) % 2 - 1).abs());
  final match = lightness - chroma / 2;
  final channels = _hueChannels(hue, chroma, x);
  return RgbColor(
    ((channels.$1 + match) * 255).round().clamp(0, 255),
    ((channels.$2 + match) * 255).round().clamp(0, 255),
    ((channels.$3 + match) * 255).round().clamp(0, 255),
  );
}

RgbColor? _parseHsv(String input) {
  final values = _parseCylindricalChannels(input, 'hsv');
  if (!_validCylindricalChannels(values)) return null;
  final hue = values![0] == 360 ? 0.0 : values[0];
  final saturation = values[1] / 100;
  final brightness = values[2] / 100;
  final chroma = brightness * saturation;
  final x = chroma * (1 - ((hue / 60) % 2 - 1).abs());
  final match = brightness - chroma;
  final channels = _hueChannels(hue, chroma, x);
  return RgbColor(
    ((channels.$1 + match) * 255).round().clamp(0, 255),
    ((channels.$2 + match) * 255).round().clamp(0, 255),
    ((channels.$3 + match) * 255).round().clamp(0, 255),
  );
}

List<String>? _functionalChannelParts(String input, String functionName) {
  var normalized = input.trim().toLowerCase();
  final prefix = '$functionName(';
  if (normalized.startsWith(prefix)) {
    if (!normalized.endsWith(')')) return null;
    normalized = normalized.substring(prefix.length, normalized.length - 1);
  } else if (normalized.contains('(') || normalized.contains(')')) {
    return null;
  }
  final parts = normalized.split(',').map((part) => part.trim()).toList();
  if (parts.length != 3) return null;
  return parts;
}

int? _parseRgbChannel(String input) {
  if (!RegExp(r'^\d{1,3}$').hasMatch(input)) return null;
  final value = int.parse(input);
  return value <= 255 ? value : null;
}

List<double>? _parseCylindricalChannels(String input, String functionName) {
  final parts = _functionalChannelParts(input, functionName);
  if (parts == null ||
      !_isDecimal(parts[0]) ||
      !_isPercentage(parts[1]) ||
      !_isPercentage(parts[2])) {
    return null;
  }
  return [
    double.parse(parts[0]),
    double.parse(parts[1].substring(0, parts[1].length - 1)),
    double.parse(parts[2].substring(0, parts[2].length - 1)),
  ];
}

bool _isDecimal(String input) =>
    RegExp(r'^(?:\d+(?:\.\d+)?|\.\d+)$').hasMatch(input);

bool _isPercentage(String input) =>
    input.endsWith('%') && _isDecimal(input.substring(0, input.length - 1));

bool _validCylindricalChannels(List<double>? values) =>
    values != null &&
    values.length == 3 &&
    values[0] >= 0 &&
    values[0] <= 360 &&
    values[1] >= 0 &&
    values[1] <= 100 &&
    values[2] >= 0 &&
    values[2] <= 100;

(double, double, double) _hueChannels(double hue, double chroma, double x) =>
    switch (hue) {
      < 60 => (chroma, x, 0),
      < 120 => (x, chroma, 0),
      < 180 => (0, chroma, x),
      < 240 => (0, x, chroma),
      < 300 => (x, 0, chroma),
      _ => (chroma, 0, x),
    };

(double, double, double) _rgbToHsl(RgbColor color) {
  final red = color.red / 255;
  final green = color.green / 255;
  final blue = color.blue / 255;
  final maximum = math.max(red, math.max(green, blue));
  final minimum = math.min(red, math.min(green, blue));
  final delta = maximum - minimum;
  final lightness = (maximum + minimum) / 2;
  final saturation = delta == 0 ? 0.0 : delta / (1 - (2 * lightness - 1).abs());
  return (
    _hue(red, green, blue, maximum, delta),
    saturation * 100,
    lightness * 100,
  );
}

(double, double, double) _rgbToHsv(RgbColor color) {
  final red = color.red / 255;
  final green = color.green / 255;
  final blue = color.blue / 255;
  final maximum = math.max(red, math.max(green, blue));
  final minimum = math.min(red, math.min(green, blue));
  final delta = maximum - minimum;
  final saturation = maximum == 0 ? 0.0 : delta / maximum;
  return (
    _hue(red, green, blue, maximum, delta),
    saturation * 100,
    maximum * 100,
  );
}

double _hue(
  double red,
  double green,
  double blue,
  double maximum,
  double delta,
) {
  if (delta == 0) return 0;
  final hue = maximum == red
      ? 60 * (((green - blue) / delta) % 6)
      : maximum == green
      ? 60 * ((blue - red) / delta + 2)
      : 60 * ((red - green) / delta + 4);
  return hue < 0 ? hue + 360 : hue;
}

String _formatChannel(double value) {
  final rounded = double.parse(value.toStringAsFixed(2));
  return rounded.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
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

double _contrastRatio(RgbColor first, RgbColor second) {
  final firstLuminance = _relativeLuminance(first);
  final secondLuminance = _relativeLuminance(second);
  final lighter = math.max(firstLuminance, secondLuminance);
  final darker = math.min(firstLuminance, secondLuminance);
  return (lighter + 0.05) / (darker + 0.05);
}

String _hexColor(RgbColor color) =>
    '#${color.red.toRadixString(16).padLeft(2, '0')}'
            '${color.green.toRadixString(16).padLeft(2, '0')}'
            '${color.blue.toRadixString(16).padLeft(2, '0')}'
        .toUpperCase();
