import 'package:bill/tools/xml_tool/xml_tool_logic.dart';
import 'package:bill/tools/xml_tool/xml_tool_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats, minifies and validates XML', () {
    const source = '<note><title>提醒</title></note>';
    final formatted = processXml(source, XmlToolMode.format);
    expect(formatted.isSuccess, isTrue);
    expect(formatted.output, contains('\n  <title>'));
    expect(formatted.elementCount, 2);
    expect(processXml(source, XmlToolMode.minify).output, source);
    // 没有 schema 时格式化产生的空白也可能属于内容，压缩不能擅自删除。
    expect(
      processXml(formatted.output, XmlToolMode.minify).output,
      formatted.output,
    );
    expect(processXml(source, XmlToolMode.validate).output, 'XML 格式正确');
  });

  test('minification preserves whitespace in mixed content', () {
    const source = '<p><b>A</b> <i>B</i></p>';
    final result = processXml(source, XmlToolMode.minify);

    expect(result.isSuccess, isTrue);
    expect(result.output, source);
  });

  test('rejects empty, malformed and dangerous declarations', () {
    expect(processXml('', XmlToolMode.format).isSuccess, isFalse);
    expect(processXml('<a>', XmlToolMode.format).isSuccess, isFalse);
    expect(
      processXml(
        '<!DOCTYPE a [<!ENTITY x "value">]><a>&x;</a>',
        XmlToolMode.format,
      ).error,
      contains('DTD'),
    );
  });

  test('enforces byte and depth limits', () {
    expect(
      processXml(
        '<a>${'中' * (maxXmlInputBytes ~/ 3 + 1)}</a>',
        XmlToolMode.validate,
      ).error,
      contains('200 KB'),
    );
    final deep =
        '${List.filled(65, '<a>').join()}x${List.filled(65, '</a>').join()}';
    expect(processXml(deep, XmlToolMode.validate).error, contains('64'));
  });

  testWidgets('changes XML mode and invalidates previous result', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: XmlToolScreen()));
    await tester.tap(find.byKey(const Key('processXml')));
    await tester.pump();
    expect(find.text('格式正确'), findsOneWidget);
    await tester.tap(find.text('校验'));
    await tester.pump();
    expect(find.text('格式正确'), findsNothing);
    expect(find.text('校验 XML'), findsOneWidget);
  });
}
