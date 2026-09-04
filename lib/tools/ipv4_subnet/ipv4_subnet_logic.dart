/// 只返回网段摘要，不分配或探测网段内的主机列表。
class Ipv4SubnetResult {
  const Ipv4SubnetResult(this.values);
  final Map<String, String> values;
  String get text =>
      values.entries.map((e) => '${e.key}: ${e.value}').join('\n');
}

Ipv4SubnetResult calculateIpv4Subnet(String input) {
  if (input.length > 64) {
    throw const FormatException('地址输入不能超过 64 个字符');
  }
  final match = RegExp(
    r'^([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})/([0-9]{1,2})$',
  ).firstMatch(input);
  if (match == null || match.end != input.length) {
    throw const FormatException('请输入 IPv4 地址及前缀，例如 192.168.1.10/24');
  }
  final parts = [for (var i = 1; i <= 5; i++) match.group(i)!];
  // 拒绝前导零，以免与其他程序的八进制解释产生歧义。
  if (parts.any((s) => s.length > 1 && s.startsWith('0'))) {
    throw const FormatException('地址及前缀不能包含多余的前导零');
  }
  final numbers = parts.map(int.tryParse).toList();
  if (numbers.any((n) => n == null) ||
      numbers.take(4).any((n) => n! > 255) ||
      numbers[4]! > 32) {
    throw const FormatException('地址每段须为 0–255，前缀须为 0–32');
  }
  final prefix = numbers[4]!;
  var address = BigInt.zero;
  for (final octet in numbers.take(4)) {
    address = (address << 8) | BigInt.from(octet!);
  }
  // BigInt 避免 Web 平台 32 位位运算截断；/0 同样是常量空间计算。
  final count = BigInt.one << (32 - prefix);
  final mask = ((BigInt.one << 32) - BigInt.one) ^ (count - BigInt.one);
  final network = address & mask;
  final last = network + count - BigInt.one;
  final special = prefix >= 31;
  final values = <String, String>{
    '网络地址': _format(network),
    '子网掩码': _format(mask),
    '广播地址': special ? '不适用' : _format(last),
    '起始可用地址': _format(special ? network : network + BigInt.one),
    '结束可用地址': _format(special ? last : last - BigInt.one),
    '可用地址数': '${special ? count : count - BigInt.two}',
    if (special) '网段说明': prefix == 31 ? '点对点链路，两端地址均可用' : '单主机地址',
  };
  return Ipv4SubnetResult(Map.unmodifiable(values));
}

String _format(BigInt value) => [
  24,
  16,
  8,
  0,
].map((shift) => ((value >> shift) & BigInt.from(255)).toString()).join('.');
