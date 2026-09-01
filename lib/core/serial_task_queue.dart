import 'dart:async';

/// 将异步写任务按提交顺序串行执行。
///
/// 单次任务失败只反馈给该调用方，不会阻断后续较新的状态继续保存。
class SerialTaskQueue {
  Future<void> _tail = Future<void>.value();

  Future<T> run<T>(Future<T> Function() task) {
    final completer = Completer<T>();
    _tail = _tail.then((_) async {
      try {
        completer.complete(await task());
      } on Object catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }
}
