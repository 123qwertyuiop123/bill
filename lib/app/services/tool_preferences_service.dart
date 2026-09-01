import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../core/atomic_file_writer.dart';
import '../../core/serial_task_queue.dart';

/// 工具箱偏好快照，仅包含工具 ID，不包含账本、密码或文本工具中的内容。
class ToolPreferencesSnapshot {
  const ToolPreferencesSnapshot({
    this.favoriteIds = const <String>{},
    this.recentIds = const <String>[],
  });

  final Set<String> favoriteIds;
  final List<String> recentIds;
}

/// 使用应用内部目录保存收藏和最近使用。
///
/// 写入时先生成临时文件再替换正式文件，降低应用被中断时配置损坏的概率。
class ToolPreferencesService {
  ToolPreferencesService({this.fileProvider});

  static const _fileName = 'toolbox_preferences.json';
  final Future<File> Function()? fileProvider;
  final SerialTaskQueue _writes = SerialTaskQueue();

  Future<File> _file() async {
    final provider = fileProvider;
    if (provider != null) return provider();
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}${Platform.pathSeparator}$_fileName');
  }

  Future<ToolPreferencesSnapshot> load() async {
    try {
      final file = await _file();
      await AtomicFileWriter.recover(file);
      if (!await file.exists()) return const ToolPreferencesSnapshot();
      final value = jsonDecode(await file.readAsString());
      if (value is! Map<String, dynamic>) {
        return const ToolPreferencesSnapshot();
      }
      return ToolPreferencesSnapshot(
        favoriteIds: _safeIds(value['favorites']).toSet(),
        recentIds: _safeIds(value['recent']).take(8).toList(),
      );
    } on Object {
      // 损坏的偏好不应阻止工具箱启动，直接使用安全默认值。
      return const ToolPreferencesSnapshot();
    }
  }

  Future<void> save(ToolPreferencesSnapshot snapshot) async {
    // 在进入队列前冻结快照，避免后续界面操作改变本次应写入的内容。
    final content = jsonEncode({
      'favorites': snapshot.favoriteIds.toList()..sort(),
      'recent': snapshot.recentIds.take(8).toList(),
    });
    await _writes.run(() async {
      final file = await _file();
      await AtomicFileWriter.writeString(file, content);
    });
  }

  List<String> _safeIds(Object? value) {
    if (value is! List) return const [];
    return value
        .whereType<String>()
        .where((id) => RegExp(r'^[a-z0-9_]{1,40}$').hasMatch(id))
        .toSet()
        .toList();
  }
}
