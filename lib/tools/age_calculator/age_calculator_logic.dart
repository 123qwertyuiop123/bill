class AgeResult {
  const AgeResult({
    required this.years,
    required this.daysLived,
    required this.daysUntilBirthday,
    required this.nextBirthday,
  });

  final int years;
  final int daysLived;
  final int daysUntilBirthday;
  final DateTime nextBirthday;
}

/// 计算周岁、已生活天数和下次生日。
///
/// 2 月 29 日出生者在非闰年按 2 月 28 日计算，避免 DateTime 自动滚动到 3 月。
AgeResult? calculateAge(DateTime birthDate, DateTime today) {
  final birth = DateTime(birthDate.year, birthDate.month, birthDate.day);
  final now = DateTime(today.year, today.month, today.day);
  if (birth.isAfter(now) || birth.year < 1900) {
    return null;
  }

  var birthdayThisYear = _birthdayInYear(birth, now.year);
  var years = now.year - birth.year;
  if (now.isBefore(birthdayThisYear)) {
    years--;
  }

  var nextBirthday = birthdayThisYear;
  if (nextBirthday.isBefore(now)) {
    nextBirthday = _birthdayInYear(birth, now.year + 1);
  }
  return AgeResult(
    years: years,
    daysLived: now.difference(birth).inDays,
    daysUntilBirthday: nextBirthday.difference(now).inDays,
    nextBirthday: nextBirthday,
  );
}

DateTime _birthdayInYear(DateTime birth, int year) {
  if (birth.month == 2 && birth.day == 29 && !_isLeapYear(year)) {
    return DateTime(year, 2, 28);
  }
  return DateTime(year, birth.month, birth.day);
}

bool _isLeapYear(int year) =>
    year % 400 == 0 || (year % 4 == 0 && year % 100 != 0);
