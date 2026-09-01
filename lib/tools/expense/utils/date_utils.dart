const _weekdays = ['星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'];

String weekdayText(DateTime date) => _weekdays[date.weekday - 1];

String shortWeekdayText(DateTime date) =>
    weekdayText(date).replaceFirst('星期', '周');

String monthText(DateTime date) => '${date.year}年${date.month}月';

String dayText(DateTime date) => '${date.month}月${date.day}日';

bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
