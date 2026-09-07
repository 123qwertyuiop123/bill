import 'package:bill/tools/text_tools/text_tools_logic.dart';
import 'package:bill/tools/text_tools/text_tools_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('encodes structural HTML characters', () {
    final result = encodeHtmlEntities('<div title="ZM">A&B\'s</div>');

    expect(
      result.text,
      '&lt;div title=&quot;ZM&quot;&gt;A&amp;B&#39;s&lt;/div&gt;',
    );
  });

  test('decodes named, decimal and hexadecimal entities strictly', () {
    final result = decodeHtmlEntities('&lt; &#20013; &#x6587; &unknown; &amp');

    expect(result.text, '< 中 文 &unknown; &amp');
  });

  test(
    'rejects empty and excessive input while preserving invalid entities',
    () {
      expect(encodeHtmlEntities('').isSuccess, isFalse);
      expect(
        encodeHtmlEntities('a' * (maxTextToolInputLength + 1)).isSuccess,
        isFalse,
      );
      expect(decodeHtmlEntities('&#xD800;').text, '&#xD800;');
      expect(decodeHtmlEntities('&#99999999;').text, '&#99999999;');
    },
  );

  testWidgets('switches to HTML entities and produces encoded output', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: TextToolsScreen()));

    await tester.tap(find.text('基础处理'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('HTML 实体').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('htmlEntityInput')),
      '<b>A&B</b>',
    );
    await tester.tap(find.byKey(const Key('convertHtmlEntities')));
    await tester.pump();

    final output = tester.widget<TextField>(
      find.byKey(const Key('htmlEntityOutput')),
    );
    expect(output.controller?.text, '&lt;b&gt;A&amp;B&lt;/b&gt;');
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(find.text('只转换字符，不渲染或执行 HTML'), findsOneWidget);
  });
}
