import 'package:bill/tools/markdown_preview/markdown_preview_logic.dart';
import 'package:bill/tools/markdown_preview/markdown_preview_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses the supported markdown subset', () {
    final result = parseMarkdownPreview('# 标题\n- 列表\n```\n代码\n```');

    expect(result.isSuccess, isTrue);
    expect(result.blocks.map((item) => item.type), [
      MarkdownBlockType.heading,
      MarkdownBlockType.bullet,
      MarkdownBlockType.code,
    ]);
  });

  test('rejects empty, excessive and unfinished code input', () {
    expect(parseMarkdownPreview('').isSuccess, isFalse);
    expect(
      parseMarkdownPreview('a' * (maxMarkdownLength + 1)).isSuccess,
      isFalse,
    );
    expect(parseMarkdownPreview('```\n代码').error, contains('结束标记'));
  });

  test('keeps HTML as plain preview text', () {
    final result = parseMarkdownPreview('<script>危险内容</script>');

    expect(result.blocks.single.text, '<script>危险内容</script>');
  });

  testWidgets('updates preview only after the action button', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MarkdownPreviewScreen()));

    expect(find.text('项目说明'), findsNothing);
    await tester.tap(find.byKey(const Key('updateMarkdownPreview')));
    await tester.pump();

    expect(find.text('预览结果'), findsOneWidget);
    expect(find.text('项目说明', findRichText: true), findsOneWidget);
  });
}
