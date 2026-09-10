import 'package:bill/tools/port_reference/port_reference_logic.dart';
import 'package:bill/tools/port_reference/port_reference_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('looks up ports by number and service name', () {
    expect(lookupPorts('443', PortProtocolFilter.all).single.service, 'HTTPS');
    expect(lookupPorts('dns', PortProtocolFilter.all).single.port, 53);
  });

  test('filters TCP and UDP entries', () {
    final udp = lookupPorts('', PortProtocolFilter.udp);
    expect(udp, isNotEmpty);
    expect(udp.every((item) => item.protocol != PortProtocol.tcp), isTrue);
    expect(lookupPorts('80', PortProtocolFilter.udp), isEmpty);
  });

  test('validates query length and port range boundaries', () {
    expect(lookupPorts('0', PortProtocolFilter.all), isEmpty);
    expect(lookupPorts('65535', PortProtocolFilter.all), isEmpty);
    expect(
      () => lookupPorts('65536', PortProtocolFilter.all),
      throwsFormatException,
    );
    expect(
      () => lookupPorts('a' * (maxPortQueryLength + 1), PortProtocolFilter.all),
      throwsFormatException,
    );
  });

  testWidgets('queries a service and switches protocol filter', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: PortReferenceScreen()));
    await tester.enterText(find.byKey(const Key('portQuery')), '443');
    await tester.tap(find.byKey(const Key('lookupPort')));
    await tester.pump();
    expect(find.text('HTTPS'), findsOneWidget);
    expect(find.text('HTTP'), findsNothing);
    await tester.tap(find.text('UDP'));
    await tester.pump();
    expect(find.text('内置资料中没有匹配结果'), findsOneWidget);
  });
}
