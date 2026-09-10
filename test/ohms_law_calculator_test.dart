import 'package:bill/tools/ohms_law_calculator/ohms_law_calculator_logic.dart';
import 'package:bill/tools/ohms_law_calculator/ohms_law_calculator_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('solves all six known-quantity combinations', () {
    const expectedVoltage = 12.0;
    const expectedCurrent = 0.12;
    const expectedResistance = 100.0;
    const expectedPower = 1.44;
    final inputs = <OhmsKnownPair, (double, double)>{
      OhmsKnownPair.voltageCurrent: (12, 0.12),
      OhmsKnownPair.voltageResistance: (12, 100),
      OhmsKnownPair.voltagePower: (12, 1.44),
      OhmsKnownPair.currentResistance: (0.12, 100),
      OhmsKnownPair.currentPower: (0.12, 1.44),
      OhmsKnownPair.resistancePower: (100, 1.44),
    };
    for (final entry in inputs.entries) {
      final result = calculateOhmsLaw(
        pair: entry.key,
        firstValue: entry.value.$1,
        secondValue: entry.value.$2,
      );
      expect(result.voltage, closeTo(expectedVoltage, 1e-10));
      expect(result.current, closeTo(expectedCurrent, 1e-10));
      expect(result.resistance, closeTo(expectedResistance, 1e-10));
      expect(result.power, closeTo(expectedPower, 1e-10));
    }
  });

  test('rejects zero, non-finite and overflowing values', () {
    for (final value in [0.0, -1.0, double.infinity, double.nan, 1e101]) {
      expect(
        () => calculateOhmsLaw(
          pair: OhmsKnownPair.voltageResistance,
          firstValue: value,
          secondValue: 100,
        ),
        throwsFormatException,
      );
    }
    expect(
      () => calculateOhmsLaw(
        pair: OhmsKnownPair.currentResistance,
        firstValue: 1e100,
        secondValue: 1e100,
      ),
      throwsFormatException,
    );
  });

  test('formats results using readable SI units', () {
    expect(formatElectricalValue(ElectricalQuantity.current, 0.12), '120 mA');
    expect(
      formatElectricalValue(ElectricalQuantity.resistance, 1000000),
      '1 MΩ',
    );
  });

  testWidgets('calculates default voltage and resistance inputs', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: OhmsLawCalculatorScreen()));
    await tester.tap(find.byKey(const Key('calculateOhmsLaw')));
    await tester.pump();
    expect(find.text('120 mA'), findsOneWidget);
    expect(find.text('1.44 W'), findsOneWidget);
    expect(find.textContaining('I = V ÷ R'), findsOneWidget);
  });
}
