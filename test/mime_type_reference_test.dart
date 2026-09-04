import 'package:bill/tools/mime_type_reference/mime_type_reference_logic.dart';
import 'package:bill/tools/mime_type_reference/mime_type_reference_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('looks up a MIME type by extension in either dot form', () {
    expect(
      lookupMimeTypes('.json', MimeLookupMode.extension).single.mime,
      'application/json',
    );
    expect(
      lookupMimeTypes('JPG', MimeLookupMode.extension).single.mime,
      'image/jpeg',
    );
  });

  test('looks up an exact MIME type and handles unknown values', () {
    final result = lookupMimeTypes('image/png', MimeLookupMode.mime).single;
    expect(result.extensions, ['png']);
    expect(
      lookupMimeTypes('application/unknown', MimeLookupMode.mime),
      isEmpty,
    );
  });

  test('rejects empty, malformed and excessive queries', () {
    expect(
      () => lookupMimeTypes('', MimeLookupMode.extension),
      throwsFormatException,
    );
    expect(
      () => lookupMimeTypes('../json', MimeLookupMode.extension),
      throwsFormatException,
    );
    expect(
      () => lookupMimeTypes('json', MimeLookupMode.mime),
      throwsFormatException,
    );
    expect(
      () => lookupMimeTypes('a' * 101, MimeLookupMode.extension),
      throwsFormatException,
    );
  });

  testWidgets('renders the JSON MIME result', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MimeTypeReferenceScreen()));

    expect(find.text('application/json'), findsOneWidget);
    expect(find.text('应用数据'), findsOneWidget);
    expect(find.text('仅按内置表查询，不读取文件内容'), findsOneWidget);
  });
}
