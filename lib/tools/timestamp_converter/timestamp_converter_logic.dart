import 'package:timezone/data/latest.dart' as time_zone_data;
import 'package:timezone/timezone.dart' as tz;

const minTimestampYear = 1900;
const maxTimestampYear = 2200;
const _millisecondThreshold = 100000000000;

bool _timeZonesInitialized = false;

class TimeZoneOption {
  const TimeZoneOption(this.id, this.label);

  final String id;
  final String label;
}

const commonTimeZones = <TimeZoneOption>[
  TimeZoneOption('UTC', '协调世界时（UTC）'),
  TimeZoneOption('Asia/Shanghai', '上海（Asia/Shanghai）'),
  TimeZoneOption('Asia/Tokyo', '东京（Asia/Tokyo）'),
  TimeZoneOption('Asia/Singapore', '新加坡（Asia/Singapore）'),
  TimeZoneOption('Europe/London', '伦敦（Europe/London）'),
  TimeZoneOption('Europe/Paris', '巴黎（Europe/Paris）'),
  TimeZoneOption('America/New_York', '纽约（America/New_York）'),
  TimeZoneOption('America/Los_Angeles', '洛杉矶（America/Los_Angeles）'),
  TimeZoneOption('Australia/Sydney', '悉尼（Australia/Sydney）'),
];

class TimeZoneConversionResult {
  const TimeZoneConversionResult({
    this.source,
    this.target,
    this.sourceZoneId,
    this.targetZoneId,
    this.transitionNotice,
    this.error,
  });

  final tz.TZDateTime? source;
  final tz.TZDateTime? target;
  final String? sourceZoneId;
  final String? targetZoneId;
  final String? transitionNotice;
  final String? error;

  bool get isSuccess => error == null;
}

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

/// 使用嵌入式 IANA 数据转换时区；不会读取位置或发起网络请求。
TimeZoneConversionResult convertTimeZone({
  required DateTime dateTime,
  required String sourceZoneId,
  required String targetZoneId,
}) {
  if (!_isSupported(dateTime)) {
    return const TimeZoneConversionResult(error: '仅支持 1900 至 2200 年');
  }
  _initializeTimeZones();

  try {
    final sourceLocation = tz.getLocation(sourceZoneId);
    final targetLocation = tz.getLocation(targetZoneId);
    final source = tz.TZDateTime(
      sourceLocation,
      dateTime.year,
      dateTime.month,
      dateTime.day,
      dateTime.hour,
      dateTime.minute,
      dateTime.second,
    );

    // 夏令时向前跳变时，库会把不存在的本地时间自动归一化；这里显式拒绝，
    // 防止用户误以为输入的墙上时间真实存在。
    if (source.year != dateTime.year ||
        source.month != dateTime.month ||
        source.day != dateTime.day ||
        source.hour != dateTime.hour ||
        source.minute != dateTime.minute ||
        source.second != dateTime.second) {
      return const TimeZoneConversionResult(error: '源时区中不存在这个本地时间，请避开夏令时跳变时段');
    }

    final target = tz.TZDateTime.from(source, targetLocation);
    final before = source.subtract(const Duration(hours: 2));
    final after = source.add(const Duration(hours: 2));
    final nearTransition =
        before.timeZoneOffset != source.timeZoneOffset ||
        after.timeZoneOffset != source.timeZoneOffset;

    return TimeZoneConversionResult(
      source: source,
      target: target,
      sourceZoneId: sourceZoneId,
      targetZoneId: targetZoneId,
      transitionNotice: nearTransition ? '该时间接近夏令时切换，结果按内置 IANA 规则处理。' : null,
    );
  } on tz.LocationNotFoundException {
    return const TimeZoneConversionResult(error: '未找到所选时区');
  } on RangeError {
    return const TimeZoneConversionResult(error: '日期超出时区数据库支持范围');
  }
}

void _initializeTimeZones() {
  if (_timeZonesInitialized) return;
  time_zone_data.initializeTimeZones();
  _timeZonesInitialized = true;
}

String formatZonedDateTime(tz.TZDateTime value) {
  String two(int number) => number.toString().padLeft(2, '0');
  return '${value.year}-${two(value.month)}-${two(value.day)} '
      '${two(value.hour)}:${two(value.minute)}:${two(value.second)}';
}

String formatUtcOffset(Duration offset) {
  final totalMinutes = offset.inMinutes;
  final sign = totalMinutes < 0 ? '-' : '+';
  final absolute = totalMinutes.abs();
  final hours = (absolute ~/ 60).toString().padLeft(2, '0');
  final minutes = (absolute % 60).toString().padLeft(2, '0');
  return 'UTC$sign$hours:$minutes';
}
