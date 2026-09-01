import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../core/atomic_file_writer.dart';
import '../../core/serial_task_queue.dart';
import 'tally_counter_model.dart';

/// 计数器使用独立内部文件，不与账本或工具箱偏好混合。
class TallyCounterService {
  TallyCounterService({this.fileProvider});

  final Future<File> Function()? fileProvider;
  final SerialTaskQueue _writes = SerialTaskQueue();

  Future<File> _file() async {
    final provider = fileProvider;
    if (provider != null) return provider();
    final directory = await getApplicationDocumentsDirectory();
    return File(
      '${directory.path}${Platform.pathSeparator}tally_counters.json',
    );
  }

  Future<List<TallyCounter>> load() async {
    try {
      final file = await _file();
      await AtomicFileWriter.recover(file);
      if (!await file.exists()) return const [];
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! List) return const [];
      return decoded
          .map(TallyCounter.tryFromJson)
          .whereType<TallyCounter>()
          .take(100)
          .toList();
    } on Object {
      return const [];
    }
  }

  Future<void> save(List<TallyCounter> counters) async {
    final content = jsonEncode(
      counters.take(100).map((item) => item.toJson()).toList(),
    );
    await _writes.run(() async {
      final file = await _file();
      await AtomicFileWriter.writeString(file, content);
    });
  }
}
