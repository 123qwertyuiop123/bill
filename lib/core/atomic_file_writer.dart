import 'dart:io';

/// 为本地持久化文件提供可恢复的替换写入。
///
/// 新内容先写入同目录临时文件并回读校验，旧文件随后改名为备份，最后才提交
/// 新文件。若进程在两次改名之间退出，下次读取前可通过 [recover] 恢复旧版本。
class AtomicFileWriter {
  const AtomicFileWriter._();

  static Future<void> writeString(File target, String content) async {
    await recover(target);
    final temporary = File('${target.path}.tmp');
    final backup = File('${target.path}.bak');

    try {
      if (await temporary.exists()) await temporary.delete();
      await temporary.writeAsString(content, flush: true);
      if (await temporary.readAsString() != content) {
        throw const FileSystemException('Temporary file verification failed');
      }

      if (await backup.exists()) await backup.delete();
      if (await target.exists()) await target.rename(backup.path);
      try {
        await temporary.rename(target.path);
      } on FileSystemException {
        if (!await target.exists() && await backup.exists()) {
          await backup.rename(target.path);
        }
        rethrow;
      }

      // 新文件已经提交；备份清理失败不应把一次成功保存报告为失败。
      try {
        if (await backup.exists()) await backup.delete();
      } on FileSystemException {
        // 下次 recover 会清理这份已经过期的备份。
      }
    } on FileSystemException {
      try {
        if (await temporary.exists()) await temporary.delete();
        if (!await target.exists() && await backup.exists()) {
          await backup.rename(target.path);
        }
      } on FileSystemException {
        // 保留原始异常；备份仍留在同目录，后续读取可以再次恢复。
      }
      rethrow;
    }
  }

  /// 恢复上一次被中断的替换，不会用临时文件覆盖已确认的旧版本。
  static Future<void> recover(File target) async {
    final temporary = File('${target.path}.tmp');
    final backup = File('${target.path}.bak');
    if (!await target.exists() && await backup.exists()) {
      await backup.rename(target.path);
    }
    if (await target.exists()) {
      if (await backup.exists()) await backup.delete();
      if (await temporary.exists()) await temporary.delete();
    }
  }
}
