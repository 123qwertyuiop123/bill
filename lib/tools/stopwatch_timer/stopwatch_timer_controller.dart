import 'dart:async';

import 'package:flutter/foundation.dart';

enum TimerToolMode { stopwatch, countdown }

/// 用系统时钟计算经过时间，避免依赖定时器触发次数产生累计漂移。
class StopwatchTimerController extends ChangeNotifier {
  TimerToolMode mode = TimerToolMode.stopwatch;
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _ticker;
  Duration countdownDuration = const Duration(minutes: 5);
  Duration countdownRemaining = const Duration(minutes: 5);
  DateTime? _countdownEnd;
  final List<Duration> laps = [];

  bool get running => mode == TimerToolMode.stopwatch
      ? _stopwatch.isRunning
      : _countdownEnd != null;
  Duration get displayed =>
      mode == TimerToolMode.stopwatch ? _stopwatch.elapsed : countdownRemaining;

  void setMode(TimerToolMode next) {
    if (mode == next) return;
    _stopAll();
    mode = next;
    notifyListeners();
  }

  void setCountdownMinutes(int minutes) {
    if (running) return;
    final safeMinutes = minutes.clamp(1, 24 * 60);
    countdownDuration = Duration(minutes: safeMinutes);
    countdownRemaining = countdownDuration;
    notifyListeners();
  }

  void toggle() => running ? pause() : start();

  void start() {
    if (running) return;
    if (mode == TimerToolMode.stopwatch) {
      _stopwatch.start();
    } else {
      if (countdownRemaining <= Duration.zero) {
        countdownRemaining = countdownDuration;
      }
      _countdownEnd = DateTime.now().add(countdownRemaining);
    }
    _ticker ??= Timer.periodic(
      const Duration(milliseconds: 50),
      (_) => _tick(),
    );
    notifyListeners();
  }

  void pause() {
    if (mode == TimerToolMode.stopwatch) {
      _stopwatch.stop();
    } else if (_countdownEnd != null) {
      countdownRemaining = _remainingNow();
      _countdownEnd = null;
    }
    _ticker?.cancel();
    _ticker = null;
    notifyListeners();
  }

  void reset() {
    _stopAll();
    _stopwatch.reset();
    laps.clear();
    countdownRemaining = countdownDuration;
    notifyListeners();
  }

  void addLap() {
    if (mode != TimerToolMode.stopwatch || !_stopwatch.isRunning) return;
    laps.insert(0, _stopwatch.elapsed);
    if (laps.length > 99) laps.removeLast();
    notifyListeners();
  }

  void _tick() {
    if (mode == TimerToolMode.countdown) {
      countdownRemaining = _remainingNow();
      if (countdownRemaining == Duration.zero) {
        _countdownEnd = null;
        _ticker?.cancel();
        _ticker = null;
      }
    }
    notifyListeners();
  }

  Duration _remainingNow() {
    final end = _countdownEnd;
    if (end == null) return countdownRemaining;
    final remaining = end.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  void _stopAll() {
    _stopwatch.stop();
    if (_countdownEnd != null) countdownRemaining = _remainingNow();
    _countdownEnd = null;
    _ticker?.cancel();
    _ticker = null;
  }

  @override
  void dispose() {
    _stopAll();
    super.dispose();
  }
}

String formatTimerDuration(Duration value) {
  if (value.isNegative) value = Duration.zero;
  final totalCentiseconds = value.inMilliseconds ~/ 10;
  final hours = totalCentiseconds ~/ 360000;
  final minutes = (totalCentiseconds ~/ 6000) % 60;
  final seconds = (totalCentiseconds ~/ 100) % 60;
  final centiseconds = totalCentiseconds % 100;
  return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${centiseconds.toString().padLeft(2, '0')}';
}
