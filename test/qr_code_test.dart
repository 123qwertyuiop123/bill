import 'package:bill/tools/qr_code/qr_code_logic.dart';
import 'package:bill/tools/qr_code/qr_code_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normalizes supported linear barcode formats', () {
    expect(
      normalizeLinearBarcode('ZM-2026-001', LinearBarcodeType.code128),
      'ZM-2026-001',
    );
    expect(
      normalizeLinearBarcode('400638133393', LinearBarcodeType.ean13),
      '4006381333931',
    );
    expect(
      normalizeLinearBarcode('03600029145', LinearBarcodeType.upcA),
      '036000291452',
    );
    expect(
      normalizeLinearBarcode('4006381333931', LinearBarcodeType.ean13),
      '4006381333931',
    );
  });

  test('rejects invalid barcode length characters and checksum', () {
    for (final action in [
      () => normalizeLinearBarcode('', LinearBarcodeType.code128),
      () => normalizeLinearBarcode('中文', LinearBarcodeType.code128),
      () => normalizeLinearBarcode('123', LinearBarcodeType.ean13),
      () => normalizeLinearBarcode('4006381333932', LinearBarcodeType.ean13),
      () => normalizeLinearBarcode('036000291453', LinearBarcodeType.upcA),
    ]) {
      expect(action, throwsFormatException);
    }
  });

  testWidgets('generates QR then switches to a linear barcode', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: QrCodeScreen()));
    await tester.enterText(find.byKey(const Key('codeInput')), ' hello ');
    await tester.ensureVisible(find.byKey(const Key('generateCode')));
    await tester.tap(find.byKey(const Key('generateCode')));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('generatedCodeText')), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('generatedCodeText'))).data,
      ' hello ',
    );

    await tester.drag(find.byType(ListView), const Offset(0, 1000));
    await tester.pumpAndSettle();
    await tester.tap(find.text('一维条码'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('generatedCodeText')), findsNothing);
    await tester.enterText(find.byKey(const Key('codeInput')), 'ZM-2026-001');
    await tester.ensureVisible(find.byKey(const Key('generateCode')));
    await tester.tap(find.byKey(const Key('generateCode')));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(find.text('ZM-2026-001'), findsWidgets);
  });
}
