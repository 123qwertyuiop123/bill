import 'package:bill/tools/chmod_calculator/chmod_calculator_logic.dart';
import 'package:bill/tools/chmod_calculator/chmod_calculator_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('all 512 ordinary permission combinations round trip', () {
    for (var bits = 0; bits < 512; bits++) {
      final octal = bits.toRadixString(8).padLeft(3, '0');
      final value = UnixPermissions.parse(octal);
      expect(value.octal, octal);
      expect(value.bits, bits);
      for (var i = 0; i < 9; i++) {
        expect(value.enabled(i), bits & (1 << (8 - i)) != 0);
        expect(value.toggle(i).toggle(i).bits, bits);
      }
    }
    expect(UnixPermissions.parse('755').symbolic, 'rwxr-xr-x');
    expect(UnixPermissions.parse('000').symbolic, '---------');
    expect(UnixPermissions.parse('777').symbolic, 'rwxrwxrwx');
    for (final input in ['', '8', '999', '0755', '755\n', 'abc']) {
      expect(() => UnixPermissions.parse(input), throwsFormatException);
    }
    expect(() => UnixPermissions.parse('755').toggle(9), throwsRangeError);
  });
  testWidgets('checkbox and numeric input stay synchronized', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ChmodCalculatorScreen()));
    await tester.tap(find.byKey(const Key('permission1')));
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '555',
    );
    await tester.enterText(find.byType(TextField), '000');
    await tester.pump();
    expect(find.text('---------'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '888');
    await tester.pump();
    expect(find.text('三位权限只能使用 0–7'), findsOneWidget);
    expect(
      tester.widget<Checkbox>(find.byKey(const Key('permission0'))).onChanged,
      isNull,
    );
  });
}
