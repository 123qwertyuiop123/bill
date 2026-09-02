const minTimestampYear = 1900;
const maxTimestampYear = 2200;
const _millisecondThreshold = 100000000000;

class TimestampResult {
  const TimestampResult({
    this.dateTime,
    this.seconds,
    this.milliseconds,
    this.error,
  });

  final DateTime? dateTime;
  final int? seconds;
  final int? milliseconds;
  final String? error;
  bool get isSuccess => error == null;
}

/// 自动识别秒级或毫秒级 Unix 时间戳，并限制到产品支持的日期范围。
TimestampResult parseUnixTimestamp(String input) {
  final normalized = input.trim();
  if (normalized.isEmpty) return const TimestampResult(error: '请输入时间戳');
  if (!RegExp(r'^-?\d{1,16}$').hasMatch(normalized)) {
    return const TimestampResult(error: '请输入不超过 16 位的整数时间戳');
  }
  final value = int.tryParse(normalized);
  if (value == null) return const TimestampResult(error: '时间戳超出支持范围');

  try {
    final milliseconds = value.abs() < _millisecondThreshold
        ? value * 1000
        : value;
    final dateTime = DateTime.fromMillisecondsSinceEpoch(
      milliseconds,
      isUtc: true,
    ).toLocal();
    if (!_isSupported(dateTime)) {
      return const TimestampResult(error: '仅支持 1900 至 2200 年');
    }
    return TimestampResult(
      dateTime: dateTime,
      seconds: milliseconds ~/ 1000,
      milliseconds: milliseconds,
    );
  } on RangeError {
    return const TimestampResult(error: '时间戳超出支持范围');
  }
}

TimestampResult convertDateToTimestamp(DateTime dateTime) {
  if (!_isSupported(dateTime)) {
    return const TimestampResult(error: '仅支持 1900 至 2200 年');
  }
  final milliseconds = dateTime.toUtc().millisecondsSinceEpoch;
  return TimestampResult(
    dateTime: dateTime,
    seconds: milliseconds ~/ 1000,
    milliseconds: milliseconds,
  );
}

bool _isSupported(DateTime dateTime) =>
    dateTime.year >= minTimestampYear && dateTime.year <= maxTimestampYear;

String formatLocalDateTime(DateTime value) {
  String two(int number) => number.toString().padLeft(2, '0');
  return '${value.year}-${two(value.month)}-${two(value.day)} '
      '${two(value.hour)}:${two(value.minute)}:${two(value.second)}';
}
