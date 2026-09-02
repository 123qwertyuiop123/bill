const maxCronInputLength = 100;
const cronResultCount = 5;
const _maxScanMinutes = 5 * 366 * 24 * 60;

class CronParseResult {
  const CronParseResult({
    this.description = '',
    this.nextRuns = const [],
    this.error,
  });

  final String description;
  final List<DateTime> nextRuns;
  final String? error;
  bool get isSuccess => error == null;

  Map<String, Object?> toMessage() => {
    'description': description,
    'nextRuns': nextRuns.map((value) => value.millisecondsSinceEpoch).toList(),
    'error': error,
  };

  factory CronParseResult.fromMessage(Map<Object?, Object?> message) =>
      CronParseResult(
        description: message['description'] as String? ?? '',
        nextRuns: (message['nextRuns'] as List<Object?>? ?? const [])
            .map((value) => DateTime.fromMillisecondsSinceEpoch(value! as int))
            .toList(growable: false),
        error: message['error'] as String?,
      );
}

class _CronField {
  const _CronField(this.values, {required this.isWildcard});

  final Set<int> values;
  final bool isWildcard;
}

class _CronSchedule {
  const _CronSchedule({
    required this.minute,
    required this.hour,
    required this.dayOfMonth,
    required this.month,
    required this.dayOfWeek,
  });

  final _CronField minute;
  final _CronField hour;
  final _CronField dayOfMonth;
  final _CronField month;
  final _CronField dayOfWeek;
}

/// 解析标准 5 段 Cron；不支持秒、年份、英文月份名或平台专用扩展符号。
CronParseResult parseCronExpression(String input, {DateTime? now}) {
  final expression = input.trim();
  if (expression.isEmpty) return const CronParseResult(error: '请输入 Cron 表达式');
  if (expression.length > maxCronInputLength) {
    return const CronParseResult(error: 'Cron 表达式不能超过 100 个字符');
  }
  final parts = expression.split(RegExp(r'\s+'));
  if (parts.length != 5) {
    return const CronParseResult(error: '请输入包含 5 段的 Cron 表达式');
  }

  try {
    final schedule = _CronSchedule(
      minute: _parseField(parts[0], 0, 59, '分钟'),
      hour: _parseField(parts[1], 0, 23, '小时'),
      dayOfMonth: _parseField(parts[2], 1, 31, '日期'),
      month: _parseField(parts[3], 1, 12, '月份'),
      dayOfWeek: _parseField(parts[4], 0, 7, '星期', normalizeSunday: true),
    );
    final runs = _findNextRuns(schedule, now ?? DateTime.now());
    if (runs.length < cronResultCount) {
      return const CronParseResult(error: '未来 5 年内找不到足够的执行时间');
    }
    return CronParseResult(description: _describe(schedule), nextRuns: runs);
  } on FormatException catch (error) {
    return CronParseResult(error: error.message);
  }
}

_CronField _parseField(
  String source,
  int minimum,
  int maximum,
  String label, {
  bool normalizeSunday = false,
}) {
  final values = <int>{};
  for (final part in source.split(',')) {
    if (part.isEmpty) throw FormatException('$label字段格式无效');
    final stepParts = part.split('/');
    if (stepParts.length > 2) throw FormatException('$label步长格式无效');
    final step = stepParts.length == 2 ? int.tryParse(stepParts[1]) : 1;
    if (step == null || step <= 0 || step > maximum - minimum + 1) {
      throw FormatException('$label步长超出范围');
    }

    final base = stepParts[0];
    int start;
    int end;
    if (base == '*') {
      start = minimum;
      end = maximum;
    } else if (base.contains('-')) {
      final bounds = base.split('-');
      if (bounds.length != 2) throw FormatException('$label范围格式无效');
      start = int.tryParse(bounds[0]) ?? -1;
      end = int.tryParse(bounds[1]) ?? -1;
    } else {
      start = int.tryParse(base) ?? -1;
      end = stepParts.length == 2 ? maximum : start;
    }
    if (start < minimum || end > maximum || start > end) {
      throw FormatException('$label数值超出 $minimum-$maximum');
    }
    for (var value = start; value <= end; value += step) {
      values.add(normalizeSunday && value == 7 ? 0 : value);
    }
  }
  if (values.isEmpty) throw FormatException('$label字段不能为空');
  final completeValueCount = normalizeSunday ? 7 : maximum - minimum + 1;
  return _CronField(values, isWildcard: values.length == completeValueCount);
}

List<DateTime> _findNextRuns(_CronSchedule schedule, DateTime now) {
  final results = <DateTime>[];
  var candidate = DateTime(
    now.year,
    now.month,
    now.day,
    now.hour,
    now.minute,
  ).add(const Duration(minutes: 1));
  for (
    var scanned = 0;
    scanned < _maxScanMinutes && results.length < cronResultCount;
    scanned++
  ) {
    if (_matches(schedule, candidate)) results.add(candidate);
    candidate = candidate.add(const Duration(minutes: 1));
  }
  return results;
}

bool _matches(_CronSchedule schedule, DateTime value) {
  if (!schedule.minute.values.contains(value.minute) ||
      !schedule.hour.values.contains(value.hour) ||
      !schedule.month.values.contains(value.month)) {
    return false;
  }
  final dayMatches = schedule.dayOfMonth.values.contains(value.day);
  final weekdayMatches = schedule.dayOfWeek.values.contains(value.weekday % 7);
  if (schedule.dayOfMonth.isWildcard && schedule.dayOfWeek.isWildcard) {
    return true;
  }
  if (schedule.dayOfMonth.isWildcard) return weekdayMatches;
  if (schedule.dayOfWeek.isWildcard) return dayMatches;
  // 与常见 crontab 语义一致：日期和星期都受限时，两者满足其一即可。
  return dayMatches || weekdayMatches;
}

String _describe(_CronSchedule schedule) {
  final minutes = schedule.minute.values.toList()..sort();
  final hours = schedule.hour.values.toList()..sort();
  if (minutes.length == 1 && hours.length == 1 && schedule.month.isWildcard) {
    final time =
        '${hours.single.toString().padLeft(2, '0')}:'
        '${minutes.single.toString().padLeft(2, '0')}';
    if (schedule.dayOfMonth.isWildcard && schedule.dayOfWeek.isWildcard) {
      return '每天 $time';
    }
    final weekdays = schedule.dayOfWeek.values.toList()..sort();
    if (schedule.dayOfMonth.isWildcard &&
        _sameValues(weekdays, [1, 2, 3, 4, 5])) {
      return '每周一至周五 $time';
    }
  }
  return '按所选分钟、小时、日期、月份和星期执行';
}

bool _sameValues(List<int> first, List<int> second) {
  if (first.length != second.length) return false;
  for (var index = 0; index < first.length; index++) {
    if (first[index] != second[index]) return false;
  }
  return true;
}

String formatCronDateTime(DateTime value) {
  String two(int number) => number.toString().padLeft(2, '0');
  const weekdays = ['日', '一', '二', '三', '四', '五', '六'];
  return '${value.year}-${two(value.month)}-${two(value.day)} '
      '${two(value.hour)}:${two(value.minute)}  '
      '（周${weekdays[value.weekday % 7]}）';
}
