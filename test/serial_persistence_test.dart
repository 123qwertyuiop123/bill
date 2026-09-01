import 'dart:convert';
import 'dart:io';

import 'package:bill/app/services/tool_preferences_service.dart';
import 'package:bill/tools/tally_counter/tally_counter_model.dart';
import 'package:bill/tools/tally_counter/tally_counter_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('bill_queue_test_');
  });

  tearDown(() async {
    if (await directory.exists()) await directory.delete(recursive: true);
  });

  test('preference saves finish in submission order', () async {
    final file = File('${directory.path}${Platform.pathSeparator}prefs.json');
    final service = ToolPreferencesService(fileProvider: () async => file);

    await Future.wait([
      service.save(const ToolPreferencesSnapshot(favoriteIds: {'calculator'})),
      service.save(const ToolPreferencesSnapshot(favoriteIds: {'expense'})),
    ]);

    final decoded =
        jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    expect(decoded['favorites'], ['expense']);
  });

  test('counter saves keep the newest submitted snapshot', () async {
    final file = File(
      '${directory.path}${Platform.pathSeparator}counters.json',
    );
    final service = TallyCounterService(fileProvider: () async => file);

    await Future.wait([
      service.save(const [TallyCounter(id: 'a', name: 'A', value: 1)]),
      service.save(const [TallyCounter(id: 'a', name: 'A', value: 2)]),
      service.save(const [TallyCounter(id: 'a', name: 'A', value: 3)]),
    ]);

    expect((await service.load()).single.value, 3);
  });
}
