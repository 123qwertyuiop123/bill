import 'package:flutter/services.dart';

import '../image_optimizer_logic.dart';

class ImageOptimizerException implements Exception {
  const ImageOptimizerException(this.message);
  final String message;
}

class SelectedImageInfo {
  const SelectedImageInfo({
    required this.name,
    required this.size,
    required this.width,
    required this.height,
  });

  final String name;
  final int size;
  final int width;
  final int height;
}

class OptimizedImageInfo {
  const OptimizedImageInfo({
    required this.size,
    required this.width,
    required this.height,
  });

  final int size;
  final int width;
  final int height;
}

/// 图片字节始终留在 Android 原生层，避免大图跨 MethodChannel 复制。
class ImageOptimizerService {
  const ImageOptimizerService();

  static const _channel = MethodChannel('com.zm.bill/image_optimizer');

  Future<SelectedImageInfo?> pickImage() async {
    final value = await _invokeMap('pickImage');
    if (value == null) return null;
    final name = value['name'];
    final size = value['size'];
    final width = value['width'];
    final height = value['height'];
    if (name is! String ||
        name.isEmpty ||
        size is! int ||
        width is! int ||
        height is! int ||
        size < 0 ||
        width < 1 ||
        height < 1 ||
        size > maxImageInputBytes ||
        width * height > maxImagePixels) {
      throw const ImageOptimizerException('图片信息无效');
    }
    return SelectedImageInfo(
      name: name,
      size: size,
      width: width,
      height: height,
    );
  }

  Future<OptimizedImageInfo> optimize({
    required ImageTargetSize target,
    required int quality,
    required ImageOutputFormat format,
  }) async {
    final value = await _invokeMap('optimizeImage', <String, Object>{
      'width': target.width,
      'height': target.height,
      'quality': quality,
      'format': format.name,
    });
    if (value == null) throw const ImageOptimizerException('图片优化失败');
    final size = value['size'];
    final width = value['width'];
    final height = value['height'];
    if (size is! int ||
        width is! int ||
        height is! int ||
        size < 1 ||
        width < 1 ||
        height < 1) {
      throw const ImageOptimizerException('优化结果无效');
    }
    return OptimizedImageInfo(size: size, width: width, height: height);
  }

  Future<String> save() async {
    try {
      final path = await _channel.invokeMethod<String>('saveOptimizedImage');
      if (path == null || path.isEmpty) {
        throw const ImageOptimizerException('图片保存失败');
      }
      return path;
    } on MissingPluginException {
      throw const ImageOptimizerException('图片优化目前仅支持 Android');
    } on PlatformException catch (error) {
      throw ImageOptimizerException(_messageFor(error.code));
    }
  }

  Future<Map<String, dynamic>?> _invokeMap(
    String method, [
    Map<String, Object>? arguments,
  ]) async {
    try {
      return await _channel.invokeMapMethod<String, dynamic>(method, arguments);
    } on MissingPluginException {
      throw const ImageOptimizerException('图片优化目前仅支持 Android');
    } on PlatformException catch (error) {
      throw ImageOptimizerException(_messageFor(error.code));
    }
  }

  String _messageFor(String code) => switch (code) {
    'image_too_large' => '图片不能超过 20 MB',
    'too_many_pixels' => '图片不能超过 2400 万像素',
    'unsupported_format' => '图片格式不受支持',
    'permission_denied' => '没有公开目录写入权限',
    'busy' => '已有图片任务正在进行，请稍候',
    'no_image' => '请先选择图片',
    'no_result' => '请先完成图片优化',
    _ => '图片处理失败，请更换图片后重试',
  };
}
