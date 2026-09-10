import 'package:bill/tools/roman_numeral_converter/roman_numeral_converter_logic.dart';
import 'package:bill/tools/roman_numeral_converter/roman_numeral_converter_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('converts decimal and Roman values in both directions', () {
    expect(integerToRoman(1), 'I');
    expect(integerToRoman(2026), 'MMXXVI');
    expect(integerToRoman(3999), 'MMMCMXCIX');
    expect(romanToInteger('MMXXVI'), 2026);
    expect(romanToInteger('mmxxvi'), 2026);
  });

  test('rejects values outside the supported decimal range', () {
    for (final value in [0, -1, 4000]) {
      expect(() => integerToRoman(value), throwsFormatException);
    }
    for (final input in ['', '1.5', '-1', '999999999999999999999999']) {
      expect(
        () => convertRoman(input, RomanConversionMode.numberToRoman),
        throwsFormatException,
      );
    }
  });

  test('rejects non-canonical Roman forms', () {
    for (final input in ['', 'IIII', 'VX', 'IC', 'ABC', 'M' * 33]) {
      expect(() => romanToInteger(input), throwsFormatException);
    }
  });

  testWidgets('converts and preserves input when changing direction', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: RomanNumeralConverterScreen()),
    );
    await tester.tap(find.byKey(const Key('convertRoman')));
    await tester.pump();
    expect(find.text('MMXXVI'), findsOneWidget);
    await tester.tap(find.text('罗马转数字'));
    await tester.pump();
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('romanInput')))
          .controller!
          .text,
      '2026',
    );
    expect(find.text('MMXXVI'), findsNothing);
    await tester.enterText(find.byKey(const Key('romanInput')), 'xiv');
    await tester.tap(find.byKey(const Key('convertRoman')));
    await tester.pump();
    expect(find.text('14'), findsOneWidget);
  });
}
