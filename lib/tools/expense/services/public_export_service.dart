import 'dart:io';

import 'package:flutter/services.dart';

class PublicExportException implements Exception {
  const PublicExportException(this.message);
  final String message;
}

/// 将应用内部 TXT 自动同步到 Android 公共下载目录。
class PublicExportService {
  static const _channel = MethodChannel('com.zm.bill/public_storage');
  static const maxExportBytes = 20 * 1024 * 1024;

  /// 自动把内部月度 TXT 同步到“下载/bill/年份”。
  ///
  /// Android 10 及以上由 MediaStore 写入公共下载目录，不申请“所有文件”权限。
  /// Android 9 及以下由原生端在获得传统存储权限后写入同一目录结构。
  Future<String?> syncTxt(
    String trustedInternalPath, {
    required int year,
    String? previousFileName,
  }) async {
    final source = File(trustedInternalPath);
    try {
      if (!await source.exists()) {
        throw const PublicExportException('TXT 文件尚未生成');
      }
      if (year < 2000 || year > 2100) {
        throw const PublicExportException('年份超出允许范围');
      }
      if (await source.length() > maxExportBytes) {
        throw const PublicExportException('TXT 文件超过20MB，无法同步到公共目录');
      }
      final fileName = source.uri.pathSegments.last;
      final location = await _channel.invokeMethod<String>(
        'syncTxtToDownloads',
        <String, Object?>{
          'bytes': await source.readAsBytes(),
          'fileName': fileName,
          'previousFileName': previousFileName,
          'year': year,
        },
      );
      return location;
    } on PublicExportException {
      rethrow;
    } on MissingPluginException {
      // 非 Android 平台没有公共 Download 目录，内部主账本仍会正常保存。
      return null;
    } on FileSystemException {
      throw const PublicExportException('无法读取应用内 TXT 文件');
    } on PlatformException catch (error) {
      if (error.code == 'permission_denied') {
        throw const PublicExportException('账本已保存，但没有公共文件夹写入权限');
      }
      throw const PublicExportException('账本已保存，但公共 TXT 同步失败');
    }
  }
}

String expectedPublicTxtPath(DateTime month, String fileName) =>
    '/storage/emulated/0/Download/bill/${month.year}/$fileName';
