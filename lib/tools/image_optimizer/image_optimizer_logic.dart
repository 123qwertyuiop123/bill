const maxImageInputBytes = 20 * 1024 * 1024;
const maxImagePixels = 24000000;
const maxImageTargetSide = 4096;

enum ImageOutputFormat {
  jpeg('JPEG'),
  png('PNG'),
  webp('WebP');

  const ImageOutputFormat(this.label);
  final String label;
}

class ImageTargetSize {
  const ImageTargetSize(this.width, this.height);

  final int width;
  final int height;
}

/// 验证目标尺寸，并按源图比例缩放到目标边界内。
ImageTargetSize calculateImageTarget({
  required String widthText,
  required String heightText,
  required int sourceWidth,
  required int sourceHeight,
  required bool keepAspectRatio,
  required bool allowUpscale,
}) {
  if (sourceWidth < 1 || sourceHeight < 1) {
    throw const FormatException('源图片尺寸无效');
  }
  final requestedWidth = _parseTargetSide(widthText, '目标宽度');
  final requestedHeight = _parseTargetSide(heightText, '目标高度');
  if (!keepAspectRatio) {
    if (!allowUpscale &&
        (requestedWidth > sourceWidth || requestedHeight > sourceHeight)) {
      throw const FormatException('已禁止放大，目标尺寸不能超过源图片');
    }
    return ImageTargetSize(requestedWidth, requestedHeight);
  }

  var scale = _minimum(
    requestedWidth / sourceWidth,
    requestedHeight / sourceHeight,
  );
  if (!allowUpscale && scale > 1) scale = 1;
  final width = (sourceWidth * scale).round().clamp(1, maxImageTargetSide);
  final height = (sourceHeight * scale).round().clamp(1, maxImageTargetSide);
  return ImageTargetSize(width, height);
}

double imageReductionPercent(int beforeBytes, int afterBytes) {
  if (beforeBytes <= 0 || afterBytes < 0) return 0;
  return ((beforeBytes - afterBytes) / beforeBytes * 100).clamp(0, 100);
}

int _parseTargetSide(String input, String label) {
  final value = int.tryParse(input.trim());
  if (value == null) throw FormatException('请输入有效的$label');
  if (value < 1 || value > maxImageTargetSide) {
    throw FormatException('$label必须在 1–$maxImageTargetSide 之间');
  }
  return value;
}

double _minimum(double first, double second) => first < second ? first : second;
