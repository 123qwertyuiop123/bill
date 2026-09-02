import 'dart:async';
import 'dart:isolate';

import 'regex_tester_logic.dart';

const regexExecutionTimeout = Duration(milliseconds: 800);

/// 在可终止的独立 Isolate 中运行用户正则，避免复杂回溯阻塞 Flutter UI。
Future<RegexToolResult> runRegexSafely({
  required String pattern,
  required String text,
  required bool global,
  required bool caseSensitive,
  required bool multiLine,
}) async {
  final port = ReceivePort();
  Isolate? isolate;
  try {
    isolate = await Isolate.spawn(_regexIsolateEntry, [
      port.sendPort,
      <String, Object>{
        'pattern': pattern,
        'text': text,
        'global': global,
        'caseSensitive': caseSensitive,
        'multiLine': multiLine,
      },
    ]);
    final message = await port.first.timeout(regexExecutionTimeout);
    return RegexToolResult.fromMessage(message as Map<Object?, Object?>);
  } on TimeoutException {
    return const RegexToolResult(error: '匹配耗时过长，请简化正则表达式');
  } on Object {
    return const RegexToolResult(error: '无法完成匹配');
  } finally {
    isolate?.kill(priority: Isolate.immediate);
    port.close();
  }
}

void _regexIsolateEntry(List<Object> arguments) {
  final sendPort = arguments[0] as SendPort;
  final request = arguments[1] as Map<Object?, Object?>;
  final result = runRegexMatch(
    pattern: request['pattern'] as String,
    text: request['text'] as String,
    global: request['global'] as bool,
    caseSensitive: request['caseSensitive'] as bool,
    multiLine: request['multiLine'] as bool,
  );
  sendPort.send(result.toMessage());
}
