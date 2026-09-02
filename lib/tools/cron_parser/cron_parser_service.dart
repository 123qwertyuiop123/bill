import 'dart:async';
import 'dart:isolate';

import 'cron_parser_logic.dart';

const cronExecutionTimeout = Duration(seconds: 3);

/// 稀疏计划最多扫描五年，放入可终止 Isolate 以保护主界面响应速度。
Future<CronParseResult> parseCronSafely(String input, {DateTime? now}) async {
  final port = ReceivePort();
  Isolate? isolate;
  try {
    isolate = await Isolate.spawn(_cronIsolateEntry, [
      port.sendPort,
      input,
      (now ?? DateTime.now()).millisecondsSinceEpoch,
    ]);
    final message = await port.first.timeout(cronExecutionTimeout);
    return CronParseResult.fromMessage(message as Map<Object?, Object?>);
  } on TimeoutException {
    return const CronParseResult(error: '计算耗时过长，请简化表达式');
  } on Object {
    return const CronParseResult(error: '无法解析 Cron 表达式');
  } finally {
    isolate?.kill(priority: Isolate.immediate);
    port.close();
  }
}

void _cronIsolateEntry(List<Object> arguments) {
  final sendPort = arguments[0] as SendPort;
  final input = arguments[1] as String;
  final now = DateTime.fromMillisecondsSinceEpoch(arguments[2] as int);
  sendPort.send(parseCronExpression(input, now: now).toMessage());
}
