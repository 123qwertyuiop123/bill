import 'package:flutter/services.dart';

import '../hash_generator_logic.dart';

class FileHashException implements Exception {
  const FileHashException(this.message);

  final String message;
}

class FileHashResult {
  const FileHashResult({
    required this.name,
    required this.size,
    required this.digest,
  });

  final String name;
  final int size;
  final String digest;
}

/// 通过 Android 系统文档选择器读取单个文件并在原生后台线程中流式计算摘要。
///
/// Dart 层不接收文件内容或 URI，避免大文件跨平台通道复制和路径泄露。
class FileHashService {
  const FileHashService();

  static const _channel = MethodChannel('com.zm.bill/file_hash');

  Future<FileHashResult?> pickAndHash(HashAlgorithm algorithm) async {
    try {
      final value = await _channel.invokeMapMethod<String, dynamic>(
        'pickAndHashFile',
        <String, Object?>{'algorithm': algorithm.platformName},
      );
      if (value == null) return null;
      final name = value['name'];
      final size = value['size'];
      final digest = value['digest'];
      if (name is! String ||
          name.isEmpty ||
          size is! int ||
          size < 0 ||
          digest is! String ||
          !isValidDigest(digest, algorithm)) {
        throw const FileHashException('文件摘要结果无效');
      }
      return FileHashResult(name: name, size: size, digest: digest);
    } on MissingPluginException {
      throw const FileHashException('文件校验目前仅支持 Android');
    } on PlatformException catch (error) {
      final message = switch (error.code) {
        'file_too_large' => '文件不能超过 512 MB',
        'busy' => '已有文件正在计算，请稍候',
        'cancelled' => '文件选择已取消',
        _ => '无法读取所选文件，请重试',
      };
      throw FileHashException(message);
    }
  }
}
