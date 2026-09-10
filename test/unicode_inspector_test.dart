import 'package:bill/tools/unicode_inspector/unicode_inspector_logic.dart';
import 'package:bill/tools/unicode_inspector/unicode_inspector_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('inspects BMP and supplementary Unicode characters', () {
    final result = inspectUnicode('中A😊');
    expect(result.isSuccess, isTrue);
    expect(result.entries, hasLength(3));
    expect(result.entries.first.codePoint, 'U+4E2D');
    expect(result.entries.last.codePoint, 'U+1F60A');
    expect(result.entries.last.utf8Hex, 'F0 9F 98 8A');
    expect(result.entries.last.utf16Hex, 'D83D DE0A');
  });

  test('reports empty input and scalar count boundary', () {
    expect(inspectUnicode('').isSuccess, isFalse);
    expect(inspectUnicode('A' * maxUnicodeScalars).isSuccess, isTrue);
    expect(
      inspectUnicode('A' * (maxUnicodeScalars + 1)).error,
      contains('256'),
    );
  });

  test('filters non-ASCII characters without changing the input', () {
    final result = inspectUnicode('中A😊', filter: UnicodeFilter.asciiOnly);
    expect(result.entries, hasLength(1));
    expect(result.entries.single.character, 'A');
  });

  testWidgets('updates rows when ASCII filter changes', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: UnicodeInspectorScreen()));
    expect(find.text('U+4E2D'), findsOneWidget);
    await tester.tap(find.text('仅 ASCII'));
    await tester.pump();
    expect(find.text('U+4E2D'), findsNothing);
    expect(find.text('U+0041'), findsOneWidget);
  });
}
