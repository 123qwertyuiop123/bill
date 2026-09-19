import 'dart:math' as math;

import 'package:bill/tools/geometry_calculator/geometry_calculator_logic.dart';
import 'package:bill/tools/geometry_calculator/geometry_calculator_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('calculates rectangle, circle and triangle', () {
    final rectangle = calculateGeometry(GeometryShape.rectangle, ['12', '8']);
    expect(rectangle.area, 96);
    expect(rectangle.perimeter, 40);
    expect(
      calculateGeometry(GeometryShape.circle, ['2']).area,
      closeTo(4 * math.pi, 1e-12),
    );
    final triangle = calculateGeometry(GeometryShape.triangle, ['3', '4', '5']);
    expect(triangle.area, 6);
    expect(triangle.perimeter, 12);
  });
  test('handles supported bounds and thin triangles', () {
    expect(
      calculateGeometry(GeometryShape.rectangle, ['1e-9', '1e-9']).area,
      closeTo(1e-18, 1e-30),
    );
    expect(
      calculateGeometry(GeometryShape.circle, ['1e9']).area.isFinite,
      isTrue,
    );
    expect(
      calculateGeometry(GeometryShape.triangle, ['1', '1', '1e-9']).area,
      closeTo(5e-10, 1e-18),
    );
  });
  test('rejects malformed lengths and invalid triangles', () {
    for (final value in [
      '',
      '0',
      '-1',
      'NaN',
      'Infinity',
      '1e10',
      '1e-10',
      '1' * 33,
    ]) {
      expect(
        () => calculateGeometry(GeometryShape.circle, [value]),
        throwsFormatException,
      );
    }
    expect(
      () => calculateGeometry(GeometryShape.rectangle, ['1']),
      throwsFormatException,
    );
    expect(
      () => calculateGeometry(GeometryShape.triangle, ['1', '2', '3']),
      throwsFormatException,
    );
  });
  testWidgets('calculates and invalidates result on shape changes', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: GeometryCalculatorScreen()),
    );
    await tester.tap(find.byKey(const Key('calculateGeometry')));
    await tester.pump();
    expect(find.text('96 单位²'), findsOneWidget);
    await tester.tap(find.text('圆形'));
    await tester.pump();
    expect(find.text('96 单位²'), findsNothing);
    expect(find.byType(TextField), findsOneWidget);
  });
}
