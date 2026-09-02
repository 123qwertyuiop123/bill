import 'package:bill/tools/base64_tool/base64_tool_logic.dart';
import 'package:bill/tools/base64_tool/base64_tool_screen.dart';
import 'package:bill/tools/json_tool/json_tool_logic.dart';
import 'package:bill/tools/json_tool/json_tool_screen.dart';
import 'package:bill/tools/number_base_converter/number_base_converter_logic.dart';
import 'package:bill/tools/number_base_converter/number_base_converter_screen.dart';
import 'package:bill/tools/timestamp_converter/timestamp_converter_logic.dart';
import 'package:bill/tools/timestamp_converter/timestamp_converter_screen.dart';
import 'package:bill/tools/url_tool/url_tool_logic.dart';
import 'package:bill/tools/url_tool/url_tool_screen.dart';
import 'package:bill/tools/uuid_generator/uuid_generator_logic.dart';
import 'package:bill/tools/uuid_generator/uuid_generator_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('JSON tool', () {
    test('formats and minifies valid JSON', () {
      expect(
        processJson('{"b":2,"a":1}', JsonToolMode.format).output,
        '{\n  "b": 2,\n  "a": 1\n}',
      );
      expect(processJson('{ "a": 1 }', JsonToolMode.minify).output, '{"a":1}');
    });

    test('rejects empty, invalid and excessive input', () {
      expect(processJson('', JsonToolMode.validate).isSuccess, isFalse);
      expect(processJson('{', JsonToolMode.validate).isSuccess, isFalse);
      expect(
        processJson(
          'x' * (maxJsonInputLength + 1),
          JsonToolMode.validate,
        ).isSuccess,
        isFalse,
      );
    });

    testWidgets('process button writes formatted output', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: JsonToolScreen()));
      await tester.tap(find.text('处理'));
      await tester.pump();

      final output = tester.widget<TextField>(
        find.byKey(const Key('jsonOutput')),
      );
      expect(output.controller?.text, contains('\n'));
    });
  });

  group('Base64 tool', () {
    test('encodes and decodes UTF-8 text', () {
      final encoded = processBase64('工具箱', Base64ToolMode.encode);
      expect(encoded.isSuccess, isTrue);
      expect(
        processBase64(encoded.output, Base64ToolMode.decode).output,
        '工具箱',
      );
    });

    test('rejects empty, invalid and excessive input', () {
      expect(processBase64('', Base64ToolMode.encode).isSuccess, isFalse);
      expect(processBase64('***', Base64ToolMode.decode).isSuccess, isFalse);
      expect(
        processBase64(
          'x' * (maxBase64InputLength + 1),
          Base64ToolMode.encode,
        ).isSuccess,
        isFalse,
      );
    });

    testWidgets('convert button writes encoded output', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Base64ToolScreen()));
      await tester.tap(find.text('转换'));
      await tester.pump();
      final output = tester.widget<TextField>(
        find.byKey(const Key('base64Output')),
      );
      expect(output.controller?.text, isNotEmpty);
    });
  });

  group('URL tool', () {
    test('encodes and decodes URI components', () {
      final encoded = processUrlText('工具 箱', UrlToolMode.encode);
      expect(encoded.isSuccess, isTrue);
      expect(processUrlText(encoded.output, UrlToolMode.decode).output, '工具 箱');
    });

    test('preserves repeated query parameters', () {
      final result = processUrlText(
        'https://example.com/?q=hello+world&page=1&page=2#part',
        UrlToolMode.query,
      );
      expect(result.isSuccess, isTrue);
      expect(result.queryEntries, hasLength(2));
      expect(result.queryEntries.last.values, ['1', '2']);
      expect(result.output, contains('q: hello world'));
    });

    test('rejects invalid and excessive input', () {
      expect(processUrlText('%ZZ', UrlToolMode.decode).isSuccess, isFalse);
      expect(processUrlText('?', UrlToolMode.query).isSuccess, isFalse);
      expect(
        processUrlText(
          'x' * (maxUrlToolInputLength + 1),
          UrlToolMode.encode,
        ).isSuccess,
        isFalse,
      );
    });

    testWidgets('process button parses query parameters', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: UrlToolScreen()));
      await tester.tap(find.text('处理'));
      await tester.pump();

      final output = tester.widget<TextField>(
        find.byKey(const Key('urlOutput')),
      );
      expect(output.controller?.text, contains('page: 1, 2'));
    });
  });

  group('timestamp converter', () {
    test('accepts seconds and milliseconds', () {
      final seconds = parseUnixTimestamp('1725148800');
      final milliseconds = parseUnixTimestamp('1725148800000');
      expect(seconds.isSuccess, isTrue);
      expect(milliseconds.isSuccess, isTrue);
      expect(seconds.milliseconds, milliseconds.milliseconds);
    });

    test('supports negative timestamps and rejects boundaries', () {
      expect(parseUnixTimestamp('-1').isSuccess, isTrue);
      expect(parseUnixTimestamp('abc').isSuccess, isFalse);
      expect(parseUnixTimestamp('9999999999999999').isSuccess, isFalse);
      expect(convertDateToTimestamp(DateTime(1899)).isSuccess, isFalse);
    });

    testWidgets('convert button writes all timestamp representations', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: TimestampConverterScreen()),
      );
      await tester.tap(find.text('转换'));
      await tester.pump();

      final output = tester.widget<TextField>(
        find.byKey(const Key('timestampOutput')),
      );
      expect(output.controller?.text, contains('毫秒：1725148800000'));
    });
  });

  group('number base converter', () {
    test('converts integers, prefixes and negatives', () {
      expect(convertNumberBase('255', 10).values[16], 'FF');
      expect(convertNumberBase('0xFF', 16).values[10], '255');
      expect(convertNumberBase('-1010', 2).values[10], '-10');
    });

    test('supports large integers and rejects invalid input', () {
      expect(convertNumberBase('1${'0' * 100}', 2).isSuccess, isTrue);
      expect(convertNumberBase('2', 2).isSuccess, isFalse);
      expect(convertNumberBase('', 10).isSuccess, isFalse);
      expect(
        convertNumberBase('1' * (maxNumberBaseInputLength + 1), 10).isSuccess,
        isFalse,
      );
    });

    testWidgets('convert button writes hexadecimal output', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: NumberBaseConverterScreen()),
      );
      await tester.tap(find.text('转换'));
      await tester.pump();
      await tester.scrollUntilVisible(
        find.byKey(const Key('numberBaseOutput16')),
        300,
        scrollable: find.byType(Scrollable).first,
      );

      final output = tester.widget<TextField>(
        find.byKey(const Key('numberBaseOutput16')),
      );
      expect(output.controller?.text, 'FF');
    });
  });

  group('UUID generator', () {
    test('generates valid unique UUID v4 values', () {
      final result = generateUuidBatch(20);
      final pattern = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      );
      expect(result.isSuccess, isTrue);
      expect(result.values, hasLength(20));
      expect(result.values.toSet(), hasLength(20));
      expect(result.values.every(pattern.hasMatch), isTrue);
    });

    test('rejects unsafe batch sizes', () {
      expect(generateUuidBatch(0).isSuccess, isFalse);
      expect(generateUuidBatch(maxUuidBatchSize + 1).isSuccess, isFalse);
    });

    testWidgets('generate button renders requested UUID count', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: UuidGeneratorScreen()));
      await tester.tap(find.text('生成 UUID'));
      await tester.pump();

      expect(find.byKey(const Key('uuidOutput0')), findsOneWidget);
      expect(find.text('复制全部'), findsOneWidget);
    });
  });
}
