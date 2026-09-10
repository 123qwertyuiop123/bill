import 'package:bill/tools/totp_generator/totp_generator_logic.dart';
import 'package:bill/tools/totp_generator/totp_generator_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('matches the RFC 6238 SHA-1 reference vector', () {
    final result = generateTotp(
      secret: 'GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ',
      timestampSeconds: 59,
      digits: 8,
    );
    expect(result.code, '94287082');
    expect(result.remainingSeconds, 1);
  });

  test('supports allowed algorithms, digits and periods', () {
    for (final algorithm in TotpAlgorithm.values) {
      final result = generateTotp(
        secret: 'JBSWY3DPEHPK3PXP',
        timestampSeconds: 1700000000,
        algorithm: algorithm,
        digits: 6,
        period: 60,
      );
      expect(result.code, matches(RegExp(r'^\d{6}$')));
      expect(result.remainingSeconds, inInclusiveRange(1, 60));
    }
  });

  test('rejects empty, malformed and oversized secrets', () {
    for (final secret in [
      '',
      'ABC1',
      'ABC=DEF',
      'AAA',
      'MY==============',
      'A' * 257,
    ]) {
      expect(
        () => generateTotp(secret: secret, timestampSeconds: 1),
        throwsFormatException,
      );
    }
    expect(
      () => generateTotp(secret: 'JBSWY3DP', timestampSeconds: -1),
      throwsFormatException,
    );
  });

  test('accepts canonical padded and unpadded Base32 secrets', () {
    expect(decodeBase32Secret('MY'), [0x66]);
    expect(decodeBase32Secret('MY======'), [0x66]);
  });

  testWidgets('hides the secret and generates a transient code', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: TotpGeneratorScreen()));
    final field = tester.widget<TextField>(find.byKey(const Key('totpSecret')));
    expect(field.obscureText, isTrue);
    await tester.enterText(
      find.byKey(const Key('totpSecret')),
      'JBSWY3DPEHPK3PXP',
    );
    await tester.tap(find.byKey(const Key('generateTotp')));
    await tester.pump();
    expect(find.byKey(const Key('totpCode')), findsOneWidget);
    await tester.tap(find.byKey(const Key('toggleTotpSecret')));
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byKey(const Key('totpSecret'))).obscureText,
      isFalse,
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
