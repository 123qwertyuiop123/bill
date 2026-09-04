import 'package:bill/tools/placeholder_text/placeholder_text_logic.dart';
import 'package:bill/tools/placeholder_text/placeholder_text_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('placeholder counts, languages and bounded output', () {
    final output = generatePlaceholderText(3, 2, PlaceholderLanguage.chinese);
    expect(output.split('\n\n'), hasLength(3));
    expect(output.split('。'), hasLength(7));
    expect(
      generatePlaceholderText(20, 10, PlaceholderLanguage.latin).length,
      lessThanOrEqualTo(20000),
    );
    expect(
      () => generatePlaceholderText(0, 2, PlaceholderLanguage.chinese),
      throwsFormatException,
    );
    expect(
      () => generatePlaceholderText(21, 2, PlaceholderLanguage.chinese),
      throwsFormatException,
    );
    expect(
      () => generatePlaceholderText(1, 11, PlaceholderLanguage.chinese),
      throwsFormatException,
    );
  });
  testWidgets('generates, invalidates old output and validates empty count', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: PlaceholderTextScreen()));
    await tester.tap(find.text('生成文本'));
    await tester.pump();
    expect(find.text('生成结果'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('paragraphs')), '');
    await tester.pump();
    expect(find.text('生成结果'), findsNothing);
    await tester.tap(find.text('生成文本'));
    await tester.pump();
    expect(find.text('段落数量请输入 1–20 的整数'), findsOneWidget);
  });
}
