import 'package:bill/tools/color_contrast/color_contrast_logic.dart';
import 'package:bill/tools/color_contrast/color_contrast_screen.dart';
import 'package:bill/tools/csv_json_converter/csv_json_converter_logic.dart';
import 'package:bill/tools/csv_json_converter/csv_json_converter_screen.dart';
import 'package:bill/tools/cron_parser/cron_parser_logic.dart';
import 'package:bill/tools/cron_parser/cron_parser_screen.dart';
import 'package:bill/tools/cron_parser/cron_parser_service.dart';
import 'package:bill/tools/hash_generator/hash_generator_logic.dart';
import 'package:bill/tools/hash_generator/hash_generator_screen.dart';
import 'package:bill/tools/hash_generator/services/file_hash_service.dart';
import 'package:bill/tools/jwt_viewer/jwt_viewer_logic.dart';
import 'package:bill/tools/jwt_viewer/jwt_viewer_screen.dart';
import 'package:bill/tools/regex_tester/regex_tester_logic.dart';
import 'package:bill/tools/regex_tester/regex_tester_screen.dart';
import 'package:bill/tools/regex_tester/regex_tester_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('regex tester', () {
    test('returns global matches and positions', () {
      final result = runRegexMatch(
        pattern: r'\b[A-Za-z]+\b',
        text: 'ZM 工具 box',
        global: true,
        caseSensitive: true,
        multiLine: false,
      );
      expect(result.isSuccess, isTrue);
      expect(result.matches.map((item) => item.value), ['ZM', 'box']);
      expect(result.matches.last.start, 6);
    });

    test('rejects invalid and excessive input', () {
      expect(
        runRegexMatch(
          pattern: '[',
          text: 'text',
          global: true,
          caseSensitive: true,
          multiLine: false,
        ).isSuccess,
        isFalse,
      );
      expect(
        runRegexMatch(
          pattern: 'a',
          text: 'x' * (maxRegexTextLength + 1),
          global: true,
          caseSensitive: true,
          multiLine: false,
        ).isSuccess,
        isFalse,
      );
    });

    test('isolated runner returns without blocking the caller', () async {
      final result = await runRegexSafely(
        pattern: 'tool',
        text: 'offline tool',
        global: true,
        caseSensitive: true,
        multiLine: false,
      );
      expect(result.matches.single.value, 'tool');
    });

    testWidgets('match button renders results', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: RegexTesterScreen(
            runner:
                ({
                  required pattern,
                  required text,
                  required global,
                  required caseSensitive,
                  required multiLine,
                }) async => runRegexMatch(
                  pattern: pattern,
                  text: text,
                  global: global,
                  caseSensitive: caseSensitive,
                  multiLine: multiLine,
                ),
          ),
        ),
      );
      await tester.tap(find.text('开始匹配'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('regexResults')), findsOneWidget);
      expect(find.textContaining('匹配结果'), findsOneWidget);
    });
  });

  group('hash generator', () {
    const channel = MethodChannel('com.zm.bill/file_hash');

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('generates standard UTF-8 digests', () {
      expect(
        generateTextHash('abc', HashAlgorithm.sha256).digest,
        'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
      );
      expect(
        generateTextHash('abc', HashAlgorithm.md5).digest,
        '900150983cd24fb0d6963f7d28e17f72',
      );
    });

    test('rejects empty and excessive input', () {
      expect(generateTextHash('', HashAlgorithm.sha256).isSuccess, isFalse);
      expect(
        generateTextHash(
          'x' * (maxHashInputLength + 1),
          HashAlgorithm.sha256,
        ).isSuccess,
        isFalse,
      );
    });

    test('validates expected digests without accepting partial values', () {
      const digest =
          'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad';
      expect(isValidDigest(digest, HashAlgorithm.sha256), isTrue);
      expect(
        digestsMatch(digest, digest.toUpperCase(), HashAlgorithm.sha256),
        isTrue,
      );
      expect(
        digestsMatch(digest, digest.substring(1), HashAlgorithm.sha256),
        isFalse,
      );
    });

    test('validates the native file hash response', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            expect(call.method, 'pickAndHashFile');
            expect(call.arguments, {'algorithm': 'SHA-256'});
            return <String, Object>{
              'name': 'example.zip',
              'size': 1024,
              'digest': 'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
            };
          });

      final result = await const FileHashService().pickAndHash(
        HashAlgorithm.sha256,
      );
      expect(result?.name, 'example.zip');
      expect(result?.size, 1024);
    });

    testWidgets('generate button writes a hash', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HashGeneratorScreen()));
      await tester.tap(find.text('生成哈希'));
      await tester.pump();

      final output = tester.widget<TextField>(
        find.byKey(const Key('hashOutput')),
      );
      expect(output.controller?.text, hasLength(64));
    });

    testWidgets('file mode compares the expected digest', (tester) async {
      const digest =
          'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad';
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            channel,
            (_) async => <String, Object>{
              'name': 'example.zip',
              'size': 1024,
              'digest': digest,
            },
          );
      await tester.pumpWidget(const MaterialApp(home: HashGeneratorScreen()));

      await tester.tap(find.text('文件校验'));
      await tester.pump();
      await tester.tap(find.byKey(const Key('pickHashFile')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('expectedDigest')));
      await tester.enterText(find.byKey(const Key('expectedDigest')), digest);
      await tester.pump();

      expect(find.text('example.zip'), findsOneWidget);
      expect(find.text('校验一致'), findsOneWidget);
    });
  });

  group('color contrast', () {
    test('calculates WCAG contrast thresholds', () {
      final result = checkColorContrast('#000', '#FFFFFF');
      expect(result.isSuccess, isTrue);
      expect(result.ratio, closeTo(21, 0.001));
      expect(result.normalAaa, isTrue);
    });

    test('rejects malformed color values', () {
      expect(checkColorContrast('', '#fff').isSuccess, isFalse);
      expect(checkColorContrast('#12GG00', '#fff').isSuccess, isFalse);
    });

    testWidgets('check button renders ratio and statuses', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ColorContrastScreen()));
      await tester.tap(find.text('检查对比度'));
      await tester.pump();

      expect(find.byKey(const Key('contrastRatio')), findsOneWidget);
      expect(find.text('普通文字 AA'), findsOneWidget);
    });
  });

  group('JWT viewer', () {
    const token =
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
        'eyJzdWIiOiIxMjMiLCJleHAiOjQxMDI0NDQ4MDB9.'
        'unverified';

    test('decodes JSON and labels unverified expiry', () {
      final result = parseJwtForViewing(token, now: DateTime.utc(2026));
      expect(result.isSuccess, isTrue);
      expect(result.header['alg'], 'HS256');
      expect(result.payload['sub'], '123');
      expect(result.expiryStatus, '未过期（未验证）');
    });

    test('rejects malformed and excessive tokens', () {
      expect(parseJwtForViewing('a.b').isSuccess, isFalse);
      expect(parseJwtForViewing('a.!.c').isSuccess, isFalse);
      expect(
        parseJwtForViewing('x' * (maxJwtInputLength + 1)).isSuccess,
        isFalse,
      );
    });

    testWidgets('parse button renders payload without trust claim', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: JwtViewerScreen()));
      await tester.tap(find.text('解析'));
      await tester.pump();

      final output = tester.widget<TextField>(
        find.byKey(const Key('jwtOutput')),
      );
      expect(output.controller?.text, contains('Test User'));
      expect(find.text('仅解析结构，不验证签名'), findsOneWidget);
    });
  });

  group('CSV/JSON converter', () {
    test('converts quoted CSV to JSON and back', () {
      final json = convertCsvJson(
        'name,note\nAlice,"hello, ""tool"""',
        CsvJsonMode.csvToJson,
      );
      expect(json.isSuccess, isTrue);
      expect(json.output, contains('hello, \\"tool\\"'));

      final csv = convertCsvJson(
        '[{"name":"Alice","age":30}]',
        CsvJsonMode.jsonToCsv,
      );
      expect(csv.output, 'name,age\nAlice,30');
    });

    test('rejects malformed, nested and excessive data', () {
      expect(
        convertCsvJson('a,b\n"open,b', CsvJsonMode.csvToJson).isSuccess,
        isFalse,
      );
      expect(
        convertCsvJson('[{"a":[]}]', CsvJsonMode.jsonToCsv).isSuccess,
        isFalse,
      );
      expect(
        convertCsvJson(
          'x' * (maxCsvJsonInputLength + 1),
          CsvJsonMode.csvToJson,
        ).isSuccess,
        isFalse,
      );
    });

    testWidgets('convert button writes JSON output', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: CsvJsonConverterScreen()),
      );
      await tester.ensureVisible(find.text('转换'));
      await tester.pump();
      await tester.tap(find.text('转换'));
      await tester.pump();

      final output = tester.widget<TextField>(
        find.byKey(const Key('csvJsonOutput')),
      );
      expect(output.controller?.text, contains('Alice'));
    });
  });

  group('Cron parser', () {
    test('parses weekday schedule and returns local runs', () {
      final result = parseCronExpression(
        '0 9 * * 1-5',
        now: DateTime(2026, 9, 4, 10),
      );
      expect(result.isSuccess, isTrue);
      expect(result.description, '每周一至周五 09:00');
      expect(result.nextRuns, hasLength(5));
      expect(result.nextRuns.first, DateTime(2026, 9, 7, 9));
    });

    test('supports steps and rejects invalid fields', () {
      final stepped = parseCronExpression(
        '*/15 * * * *',
        now: DateTime(2026, 9, 2, 10, 1),
      );
      expect(stepped.nextRuns.first.minute, 15);
      expect(parseCronExpression('60 * * * *').isSuccess, isFalse);
      expect(parseCronExpression('* * *').isSuccess, isFalse);
    });

    test('isolated runner returns future executions', () async {
      final result = await parseCronSafely(
        '0 9 * * 1-5',
        now: DateTime(2026, 9, 4, 10),
      );
      expect(result.isSuccess, isTrue);
      expect(result.nextRuns, hasLength(5));
    });

    testWidgets('parse button renders description and next runs', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CronParserScreen(
            runner: (input) async =>
                parseCronExpression(input, now: DateTime(2026, 9, 4, 10)),
          ),
        ),
      );
      await tester.tap(find.text('解析'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('cronDescription')), findsOneWidget);
      expect(find.byKey(const Key('cronNextRuns')), findsOneWidget);
    });
  });
}
