import 'package:bill/tools/resistor_decoder/resistor_decoder_logic.dart';
import 'package:bill/tools/resistor_decoder/resistor_decoder_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('decodes four and five bands with tolerance', () {
    final result = decodeResistorBands([
      ResistorColor.brown,
      ResistorColor.black,
      ResistorColor.red,
      ResistorColor.gold,
    ]);
    expect(result.ohms, 1000);
    expect(result.minimum, 950);
    expect(result.maximum, 1050);
    expect(
      decodeResistorBands([
        ResistorColor.brown,
        ResistorColor.black,
        ResistorColor.black,
        ResistorColor.brown,
        ResistorColor.brown,
      ]).ohms,
      1000,
    );
  });
  test('decodes SMD numeric codes including zero and exponent boundaries', () {
    expect(decodeSmdResistor('102').ohms, 1000);
    expect(decodeSmdResistor('1001').ohms, 1000);
    expect(decodeSmdResistor('000').ohms, 0);
    expect(decodeSmdResistor('9999').ohms, 999e9);
    expect(decodeSmdResistor('102').tolerancePercent, isNull);
  });
  test('rejects invalid positions and complete oversized inputs', () {
    for (final input in ['', '12', '10000', '01A', '１０２', '102\n']) {
      expect(() => decodeSmdResistor(input), throwsFormatException);
    }
    expect(
      () => decodeResistorBands([
        ResistorColor.black,
        ResistorColor.black,
        ResistorColor.red,
        ResistorColor.gold,
      ]),
      throwsFormatException,
    );
    expect(() => decodeResistorBands([]), throwsFormatException);
  });
  testWidgets('decodes defaults and switches to SMD workflow', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ResistorDecoderScreen()));
    await tester.ensureVisible(find.byKey(const Key('decodeResistor')));
    await tester.tap(find.byKey(const Key('decodeResistor')));
    await tester.pump();
    expect(find.text('1 kΩ'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, 1000));
    await tester.pumpAndSettle();
    await tester.tap(find.text('贴片编码'));
    await tester.pump();
    expect(find.text('1 kΩ'), findsNothing);
    await tester.enterText(find.byKey(const Key('smdInput')), '1001');
    await tester.tap(find.byKey(const Key('decodeResistor')));
    await tester.pump();
    expect(find.text('数字编码无法确定'), findsOneWidget);
  });
}
