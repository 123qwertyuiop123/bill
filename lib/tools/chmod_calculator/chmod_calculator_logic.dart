/// 普通九位 Unix 权限的值对象；不包含路径、特殊权限或执行命令的能力。
class UnixPermissions {
  const UnixPermissions._(this.bits);
  final int bits;

  static UnixPermissions parse(String input) {
    if (input.length != 3 || !RegExp(r'^[0-7]{3}$').hasMatch(input)) {
      throw const FormatException('三位权限只能使用 0–7');
    }
    return UnixPermissions._(int.parse(input, radix: 8));
  }

  String get octal => bits.toRadixString(8).padLeft(3, '0');
  String get symbolic => List.generate(
    9,
    (i) => bits & (1 << (8 - i)) != 0 ? 'rwx'[i % 3] : '-',
  ).join();

  bool enabled(int index) {
    RangeError.checkValueInInterval(index, 0, 8, 'index');
    return bits & (1 << (8 - index)) != 0;
  }

  UnixPermissions toggle(int index) {
    RangeError.checkValueInInterval(index, 0, 8, 'index');
    return UnixPermissions._(bits ^ (1 << (8 - index)));
  }
}
