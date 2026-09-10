import 'package:bill/tools/statistics_calculator/statistics_calculator_logic.dart';
import 'package:bill/tools/statistics_calculator/statistics_calculator_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('calculates descriptive statistics for a numeric list', () {
    final result = calculateStatistics('12, 18 20\n25,30');
    expect(result.count, 5);
    expect(result.sum, 105);
    expect(result.mean, 21);
    expect(result.median, 20);
    expect(result.minimum, 12);
    expect(result.maximum, 30);
    expect(result.range, 18);
    expect(result.populationStandardDeviation, closeTo(6.131883, 1e-6));
    expect(result.sampleStandardDeviation, closeTo(6.855655, 1e-6));
  });

  test('handles one value and even-sized medians', () {
    final one = calculateStatistics('4');
    expect(one.populationStandardDeviation, 0);
    expect(one.sampleStandardDeviation, isNull);
    expect(calculateStatistics('1, 2, 3, 4').median, 2.5);
  });

  test('rejects empty, malformed, non-finite and oversized input', () {
    for (final input in ['', ' ', '1，2', '1,abc', 'NaN', 'Infinity']) {
      expect(() => calculateStatistics(input), throwsFormatException);
    }
    expect(
      () => calculateStatistics(List.filled(10001, '1').join(',')),
      throwsFormatException,
    );
    expect(
      () => calculateStatistics('1' * (maxStatisticsInputLength + 1)),
      throwsFormatException,
    );
  });

  test('invalid value errors identify position without echoing input', () {
    const sensitiveToken = 'private-value';

    expect(
      () => calculateStatistics('1,$sensitiveToken,3'),
      throwsA(
        isA<FormatException>()
            .having((error) => error.message, 'message', contains('第 2 项'))
            .having(
              (error) => error.message,
              'message',
              isNot(contains(sensitiveToken)),
            ),
      ),
    );
  });

  testWidgets('calculates and clears stale results after editing', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: StatisticsCalculatorScreen()),
    );
    await tester.tap(find.byKey(const Key('calculateStatistics')));
    await tester.pump();
    expect(find.text('21'), findsOneWidget);
    expect(find.text('6.131884'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('statisticsInput')), '1');
    await tester.pump();
    expect(find.text('6.131884'), findsNothing);
  });
}
