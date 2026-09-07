import 'package:bill/tools/aspect_ratio_calculator/aspect_ratio_calculator_logic.dart';
import 'package:bill/tools/aspect_ratio_calculator/aspect_ratio_calculator_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reduces dimensions and scales both directions', () {
    final result = calculateAspectRatio('1920', '1080');

    expect(result.ratioLabel, '16 : 9');
    expect(result.decimal, closeTo(1.7778, 0.0001));
    expect(result.heightForWidth(1280), 720);
    expect(result.widthForHeight(720), 1280);
  });

  test('reports square and portrait orientations', () {
    expect(calculateAspectRatio('100', '100').orientation, '正方形');
    expect(calculateAspectRatio('9', '16').orientation, '纵向');
  });

  test('rejects empty, zero and excessive dimensions', () {
    expect(() => calculateAspectRatio('', '10'), throwsFormatException);
    expect(() => calculateAspectRatio('0', '10'), throwsFormatException);
    expect(
      () => calculateAspectRatio('${maxAspectDimension + 1}', '10'),
      throwsFormatException,
    );
  });

  testWidgets('calculates and applies a preset', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AspectRatioCalculatorScreen()),
    );

    expect(find.text('16 : 9'), findsOneWidget);
    await tester.tap(find.text('1:1'));
    await tester.pump();

    expect(find.text('1 : 1'), findsOneWidget);
    expect(find.text('正方形'), findsOneWidget);
  });

  testWidgets('does not truncate an excessive pasted dimension', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: AspectRatioCalculatorScreen()),
    );
    await tester.enterText(find.byType(TextField).first, '1000000');
    await tester.tap(find.byKey(const Key('calculateAspectRatio')));
    await tester.pump();

    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller?.text,
      '1000000',
    );
    expect(find.textContaining('宽度必须在'), findsOneWidget);
  });
}
