import 'package:bill/tools/ipv4_subnet/ipv4_subnet_logic.dart';
import 'package:bill/tools/ipv4_subnet/ipv4_subnet_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('subnet sample and /0 /31 /32 edge cases', () {
    final sample = calculateIpv4Subnet('192.168.1.10/24').values;
    expect(sample['网络地址'], '192.168.1.0');
    expect(sample['子网掩码'], '255.255.255.0');
    expect(sample['广播地址'], '192.168.1.255');
    expect(sample['可用地址数'], '254');
    final all = calculateIpv4Subnet('255.255.255.255/0').values;
    expect(all['起始可用地址'], '0.0.0.1');
    expect(all['结束可用地址'], '255.255.255.254');
    expect(all['可用地址数'], '4294967294');
    final pair = calculateIpv4Subnet('192.168.1.11/31').values;
    expect(pair['起始可用地址'], '192.168.1.10');
    expect(pair['结束可用地址'], '192.168.1.11');
    expect(pair['广播地址'], '不适用');
    expect(pair['可用地址数'], '2');
    final single = calculateIpv4Subnet('255.255.255.255/32').values;
    expect(single['可用地址数'], '1');
    expect(single['起始可用地址'], '255.255.255.255');
  });
  test('rejects malformed, ambiguous and oversized addresses', () {
    for (final value in [
      '',
      '1.2.3.256/24',
      '01.2.3.4/24',
      '1.2.3.4/33',
      '1.2.3.4/-1',
      '1.2.3.4/01',
      '1.2.3.4/24\n',
      'x' * 65,
    ]) {
      expect(
        () => calculateIpv4Subnet(value),
        throwsFormatException,
        reason: value,
      );
    }
  });
  testWidgets('calculates and clears stale subnet output', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Ipv4SubnetScreen()));
    await tester.tap(find.text('计算子网'));
    await tester.pump();
    expect(find.text('192.168.1.0'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '');
    await tester.pump();
    expect(find.text('192.168.1.0'), findsNothing);
    await tester.tap(find.text('计算子网'));
    await tester.pump();
    expect(find.textContaining('请输入 IPv4'), findsOneWidget);
  });
}
