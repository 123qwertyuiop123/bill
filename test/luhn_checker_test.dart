import 'package:bill/tools/luhn_checker/luhn_checker_logic.dart';
import 'package:bill/tools/luhn_checker/luhn_checker_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('known vectors, zero prefixes and maximum lengths', () {
    expect(processLuhn('1234', LuhnMode.generate).digit, '4');
    expect(processLuhn('12344', LuhnMode.validate).valid, isTrue);
    expect(processLuhn('12345', LuhnMode.validate).valid, isFalse);
    expect(
      processLuhn('7992739871', LuhnMode.generate).sequence,
      '79927398713',
    );
    expect(processLuhn('001234', LuhnMode.generate).sequence, '0012344');
    expect(processLuhn('00', LuhnMode.validate).valid, isTrue);
    for (var length = 1; length <= 127; length++) {
      final result = processLuhn('9' * length, LuhnMode.generate);
      expect(result.sequence, hasLength(length + 1));
      expect(processLuhn(result.sequence, LuhnMode.validate).valid, isTrue);
    }
  });
  test('rejects empty, non ASCII, spaces and oversized input', () {
    for (final input in ['', '1', '１２', '1 2', '12\n', '-12', '1' * 129]) {
      expect(
        () => processLuhn(input, LuhnMode.validate),
        throwsFormatException,
      );
    }
    expect(
      () => processLuhn('1' * 128, LuhnMode.generate),
      throwsFormatException,
    );
  });
  testWidgets('validates, clears result and changes mode safely', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LuhnCheckerScreen()));
    await tester.enterText(find.byType(TextField), '12344');
    await tester.tap(find.byKey(const Key('luhnAction')));
    await tester.pump();
    expect(find.text('校验通过'), findsOneWidget);
    await tester.tap(find.text('生成校验位'));
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '',
    );
    expect(find.text('校验通过'), findsNothing);
    await tester.enterText(find.byType(TextField), '1234');
    await tester.tap(find.byKey(const Key('luhnAction')));
    await tester.pump();
    expect(find.text('12344'), findsOneWidget);
    expect(find.text('校验通过不代表号码真实、存在或可用'), findsOneWidget);
  });
}
