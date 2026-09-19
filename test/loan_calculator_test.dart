import 'package:bill/tools/loan_calculator/loan_calculator_logic.dart';
import 'package:bill/tools/loan_calculator/loan_calculator_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('calculates fixed-rate amortization', () {
    final result = calculateLoan(
      principalText: '100000',
      annualRateText: '4.2',
      monthsText: '36',
    );
    expect(result.monthlyPayment, closeTo(2961.30, 0.01));
    expect(result.schedule, hasLength(36));
    expect(result.schedule.last.balance, closeTo(0, 1e-6));
    expect(result.totalPayment, closeTo(result.monthlyPayment * 36, 0.01));
  });

  test(
    'handles zero interest and rejects unreliable boundary combinations',
    () {
      final zero = calculateLoan(
        principalText: '1200',
        annualRateText: '0',
        monthsText: '12',
      );
      expect(zero.monthlyPayment, 100);
      expect(zero.totalInterest, 0);
      expect(
        () => calculateLoan(
          principalText: '1e12',
          annualRateText: '100',
          monthsText: '600',
        ),
        throwsFormatException,
      );
    },
  );

  test('rejects malformed and excessive input', () {
    for (final values in [
      ['', '4', '12'],
      ['0', '4', '12'],
      ['1e13', '4', '12'],
      ['100', '-1', '12'],
      ['100', '101', '12'],
      ['100', '4', '0'],
      ['100', '4', '601'],
      ['100', '4', '12.5'],
      ['1+2', '4', '12'],
    ]) {
      expect(
        () => calculateLoan(
          principalText: values[0],
          annualRateText: values[1],
          monthsText: values[2],
        ),
        throwsFormatException,
      );
    }
  });

  testWidgets('calculates and invalidates stale result after editing', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LoanCalculatorScreen()));
    await tester.ensureVisible(find.byKey(const Key('calculateLoan')));
    await tester.tap(find.byKey(const Key('calculateLoan')));
    await tester.pump();
    expect(find.text('总利息'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('loanPrincipal')), '200000');
    await tester.pump();
    expect(find.text('总利息'), findsNothing);
  });
}
