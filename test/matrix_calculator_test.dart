import 'package:bill/tools/matrix_calculator/matrix_calculator_logic.dart';
import 'package:bill/tools/matrix_calculator/matrix_calculator_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'rejects normalization loss and retains representable small determinants',
    () {
      expect(
        () => calculateMatrix([
          ['1e12', '0'],
          ['0', '1e-320'],
        ], MatrixOperation.determinant),
        throwsFormatException,
      );
      expect(
        calculateMatrix([
          ['1e12', '0'],
          ['0', '1e-200'],
        ], MatrixOperation.determinant).determinant,
        closeTo(1e-188, 1e-200),
      );
    },
  );
  const a = [
    ['1', '2'],
    ['3', '4'],
  ];
  test('determinant transpose inverse and three dimensions', () {
    expect(
      calculateMatrix(a, MatrixOperation.determinant).determinant,
      closeTo(-2, 1e-10),
    );
    expect(calculateMatrix(a, MatrixOperation.transpose).matrix, [
      [1.0, 3.0],
      [2.0, 4.0],
    ]);
    final inverse = calculateMatrix(a, MatrixOperation.inverse).matrix!;
    expect(inverse[0][0], closeTo(-2, 1e-10));
    expect(inverse[1][0], closeTo(1.5, 1e-10));
    const three = [
      ['1', '2', '3'],
      ['0', '1', '4'],
      ['5', '6', '0'],
    ];
    expect(
      calculateMatrix(three, MatrixOperation.determinant).determinant,
      closeTo(1, 1e-10),
    );
    final b = calculateMatrix(three, MatrixOperation.inverse).matrix!;
    expect(b[0][0], closeTo(-24, 1e-9));
  });
  test('singular and near singular boundaries', () {
    const singular = [
      ['1', '2'],
      ['2', '4'],
    ];
    expect(
      calculateMatrix(singular, MatrixOperation.determinant).determinant,
      0,
    );
    expect(
      () => calculateMatrix(singular, MatrixOperation.inverse),
      throwsFormatException,
    );
    expect(
      () => calculateMatrix([
        ['1', '0'],
        ['0', '1e-13'],
      ], MatrixOperation.inverse),
      throwsFormatException,
    );
    expect(
      calculateMatrix([
        ['1e12', '0'],
        ['0', '1e12'],
      ], MatrixOperation.determinant).determinant,
      1e24,
    );
    expect(
      calculateMatrix([
        ['1e-100', '0'],
        ['0', '1e-100'],
      ], MatrixOperation.inverse).matrix![0][0],
      1e100,
    );
    expect(
      () => calculateMatrix([
        ['1e-200', '0'],
        ['0', '1e-200'],
      ], MatrixOperation.determinant),
      throwsFormatException,
    );
  });
  test('bounded finite input without evaluating expressions', () {
    for (final bad in [
      'NaN',
      'Infinity',
      '1e13',
      '1+2',
      '',
      List.filled(33, '1').join(),
    ]) {
      expect(
        () => calculateMatrix([
          [bad, '0'],
          ['0', '1'],
        ], MatrixOperation.transpose),
        throwsFormatException,
      );
    }
    expect(
      () => calculateMatrix([
        ['1'],
      ], MatrixOperation.inverse),
      throwsFormatException,
    );
    expect(
      () => calculateMatrix([
        ['1', '2'],
        ['3'],
      ], MatrixOperation.inverse),
      throwsFormatException,
    );
  });
  testWidgets('result is invalidated after editing', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MatrixCalculatorScreen()));
    await tester.ensureVisible(find.byKey(const Key('calculateMatrix')));
    await tester.tap(find.byKey(const Key('calculateMatrix')));
    await tester.pumpAndSettle();
    expect(find.text('-2'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('matrix-0-0')), '2');
    await tester.pumpAndSettle();
    expect(find.text('-2'), findsNothing);
  });
}
