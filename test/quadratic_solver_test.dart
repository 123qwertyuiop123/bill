import 'package:bill/tools/quadratic_solver/quadratic_solver_logic.dart';
import 'package:bill/tools/quadratic_solver/quadratic_solver_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'does not silently classify underflowed discriminants as repeated roots',
    () {
      expect(() => solveQuadratic('1', '1e-200', '0'), throwsFormatException);
      expect(
        () => solveQuadratic('1e-200', '1', '1e-200'),
        throwsFormatException,
      );
    },
  );
  test('solves distinct, repeated and complex roots', () {
    final result = solveQuadratic('1', '-3', '2');
    expect(result.values['x₁'], '1');
    expect(result.values['x₂'], '2');
    expect(result.values['判别式 Δ'], '1');
    expect(solveQuadratic('1', '-2', '1').values['x₁ = x₂'], '1');
    expect(solveQuadratic('1', '0', '1').kind, '两个共轭复根');
  });
  test('handles linear, impossible and identity degenerations', () {
    expect(solveQuadratic('0', '2', '-4').values['x'], '2');
    expect(solveQuadratic('0', '0', '1').kind, '无解');
    expect(solveQuadratic('0', '0', '0').kind, '恒等式');
  });
  test('uses stable roots for disparate coefficients and bounded inputs', () {
    final result = solveQuadratic('1', '1e10', '1');
    expect(double.parse(result.values['x₂']!), closeTo(-1e-10, 1e-18));
    expect(solveQuadratic('1e99', '-3e99', '2e99').values['x₁'], '1');
    expect(solveQuadratic('1e100', '0', '0').values['x₁ = x₂'], '0');
    for (final value in ['', 'NaN', 'Infinity', '1e101', '1' * 33]) {
      expect(() => solveQuadratic(value, '1', '1'), throwsFormatException);
    }
    expect(() => solveQuadratic('1e-320', '1e100', '1'), throwsFormatException);
  });
  testWidgets('solves defaults and invalidates stale roots', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: QuadraticSolverScreen()));
    await tester.ensureVisible(find.byKey(const Key('solveQuadratic')));
    await tester.tap(find.byKey(const Key('solveQuadratic')));
    await tester.pump();
    expect(find.text('两个不同实根'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('coefficient-0')), '');
    await tester.pump();
    expect(find.text('两个不同实根'), findsNothing);
  });
}
