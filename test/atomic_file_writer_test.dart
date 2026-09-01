import 'dart:io';

import 'package:bill/core/atomic_file_writer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('bill_atomic_test_');
  });

  tearDown(() async {
    if (await directory.exists()) await directory.delete(recursive: true);
  });

  test('atomically replaces an existing file and removes work files', () async {
    final target = File('${directory.path}${Platform.pathSeparator}data.json');
    await target.writeAsString('old');

    await AtomicFileWriter.writeString(target, 'new');

    expect(await target.readAsString(), 'new');
    expect(await File('${target.path}.tmp').exists(), isFalse);
    expect(await File('${target.path}.bak').exists(), isFalse);
  });

  test('restores the old version after an interrupted replacement', () async {
    final target = File('${directory.path}${Platform.pathSeparator}data.json');
    final backup = File('${target.path}.bak');
    final temporary = File('${target.path}.tmp');
    await backup.writeAsString('last-good');
    await temporary.writeAsString('partial');

    await AtomicFileWriter.recover(target);

    expect(await target.readAsString(), 'last-good');
    expect(await backup.exists(), isFalse);
    expect(await temporary.exists(), isFalse);
  });
}
