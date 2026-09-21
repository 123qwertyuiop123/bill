import 'package:bill/core/app_theme.dart';
import 'package:bill/tools/password_generator/password_generator_screen.dart';
import 'package:bill/tools/password_generator/password_strength_logic.dart';
import 'package:bill/tools/timestamp_converter/timestamp_converter_logic.dart';
import 'package:bill/tools/timestamp_converter/timestamp_converter_screen.dart';
import 'package:bill/tools/uuid_generator/uuid_generator_logic.dart';
import 'package:bill/tools/uuid_generator/uuid_generator_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget home, {double textScale = 1}) => MaterialApp(
  theme: buildAppTheme(),
  locale: const Locale('zh', 'CN'),
  supportedLocales: const [Locale('zh', 'CN')],
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context)
        .copyWith(textScaler: TextScaler.linear(textScale)),
    child: child!,
  ),
  home: home,
);

void main() {
  group('密码强度评估', () {
    test('区分明显弱密码和较强密码', () {
      final weak = evaluatePasswordStrength('Password123456');
      final strong = evaluatePasswordStrength('vR7!mQ2#kL9@tX4\$pN8&');

      expect(weak.isSuccess, isTrue);
      expect(weak.score, lessThanOrEqualTo(1));
      expect(weak.warning, isNotNull);
      expect(strong.score, greaterThanOrEqualTo(3));
    });

    test('拒绝空输入和超长输入并识别重复模式', () {
      expect(evaluatePasswordStrength('').isSuccess, isFalse);
      expect(
        evaluatePasswordStrength('x' * (maxPasswordEvaluationLength + 1))
            .isSuccess,
        isFalse,
      );
      expect(evaluatePasswordStrength('abcabcabc').warning, contains('重复'));
    });

    testWidgets('评估页签显示中文结果', (tester) async {
      await tester.pumpWidget(_app(const PasswordGeneratorScreen()));
      await tester.tap(find.text('强度评估'));
      await tester.pump();
      await tester.enterText(
        find.byKey(const Key('passwordEvaluationInput')),
        'Password123456',
      );
      await tester.tap(find.byKey(const Key('evaluatePassword')));
      await tester.pump();

      expect(find.byKey(const Key('passwordStrengthResult')), findsOneWidget);
      expect(find.textContaining('检测到常见密码模式'), findsOneWidget);
    });

    testWidgets('超长密码保留原文并由逻辑层拒绝', (tester) async {
      await tester.pumpWidget(_app(const PasswordGeneratorScreen()));
      await tester.tap(find.text('强度评估'));
      await tester.pump();
      final input = find.byKey(const Key('passwordEvaluationInput'));
      final oversized = 'x' * (maxPasswordEvaluationLength + 1);

      await tester.enterText(input, oversized);
      expect(tester.widget<TextField>(input).controller!.text, oversized);
      await tester.tap(find.byKey(const Key('evaluatePassword')));
      await tester.pump();
      expect(find.text('密码最多 256 个字符'), findsOneWidget);
    });
  });

  group('世界时区换算', () {
    test('按 IANA 规则跨日期换算', () {
      final result = convertTimeZone(
        dateTime: DateTime(2026, 9, 20, 9),
        sourceZoneId: 'Asia/Shanghai',
        targetZoneId: 'America/New_York',
      );

      expect(result.isSuccess, isTrue);
      expect(result.source!.hour, 9);
      expect(result.target!.year, 2026);
      expect(result.target!.month, 9);
      expect(result.target!.day, 19);
      expect(result.target!.hour, 21);
    });

    test('拒绝不存在的夏令时本地时间和未知时区', () {
      final missing = convertTimeZone(
        dateTime: DateTime(2026, 3, 8, 2, 30),
        sourceZoneId: 'America/New_York',
        targetZoneId: 'Asia/Shanghai',
      );
      final ambiguous = convertTimeZone(
        dateTime: DateTime(2026, 11, 1, 1, 30),
        sourceZoneId: 'America/New_York',
        targetZoneId: 'Asia/Shanghai',
      );
      final unknown = convertTimeZone(
        dateTime: DateTime(2026),
        sourceZoneId: 'Invalid/Zone',
        targetZoneId: 'Asia/Shanghai',
      );

      expect(missing.isSuccess, isFalse);
      expect(missing.error, contains('不存在'));
      expect(ambiguous.isSuccess, isFalse);
      expect(ambiguous.error, contains('重复'));
      expect(unknown.isSuccess, isFalse);
    });

    test('UTC 可以作为源时区或目标时区', () {
      final toUtc = convertTimeZone(
        dateTime: DateTime(2026, 9, 20, 9),
        sourceZoneId: 'Asia/Shanghai',
        targetZoneId: 'UTC',
      );
      final fromUtc = convertTimeZone(
        dateTime: DateTime(2026, 9, 20, 1),
        sourceZoneId: 'UTC',
        targetZoneId: 'Asia/Shanghai',
      );

      expect(toUtc.isSuccess, isTrue);
      expect(toUtc.target!.hour, 1);
      expect(formatUtcOffset(toUtc.target!.timeZoneOffset), 'UTC+00:00');
      expect(fromUtc.isSuccess, isTrue);
      expect(fromUtc.target!.hour, 9);
    });

    testWidgets('时区页签生成离线换算结果', (tester) async {
      await tester.pumpWidget(_app(const TimestampConverterScreen()));
      await tester.tap(find.text('时区换算'));
      await tester.pump();
      await tester.tap(find.byKey(const Key('convertTimeZone')));
      await tester.pump();

      expect(find.byKey(const Key('timeZoneResult')), findsOneWidget);
      await tester.drag(find.byType(ListView).first, const Offset(0, -500));
      await tester.pump();
      expect(find.textContaining('按内置 IANA 时区规则'), findsOneWidget);
    });
  });

  group('UUID v7', () {
    test('生成包含指定毫秒时间的 RFC 9562 格式', () {
      final now = DateTime.fromMillisecondsSinceEpoch(
        1725148800000,
        isUtc: true,
      );
      final value = generateUuidV7(now: now);
      final compact = value.replaceAll('-', '');

      expect(
        value,
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          ),
        ),
      );
      expect(int.parse(compact.substring(0, 12), radix: 16), 1725148800000);
    });

    test('批量 v7 唯一且继续限制数量', () {
      final result = generateUuidBatch(20, version: UuidVersion.v7);
      expect(result.values, hasLength(20));
      expect(result.values.toSet(), hasLength(20));
      expect(
        generateUuidBatch(
          maxUuidBatchSize + 1,
          version: UuidVersion.v7,
        ).isSuccess,
        isFalse,
      );
    });

    testWidgets('切换 v7 后生成结果并显示安全边界', (tester) async {
      await tester.pumpWidget(_app(const UuidGeneratorScreen()));
      await tester.tap(find.text('UUID v7'));
      await tester.pump();
      await tester.tap(find.byKey(const Key('generateUuid')));
      await tester.pump();

      expect(find.byKey(const Key('uuidOutput0')), findsOneWidget);
      await tester.drag(find.byType(ListView).first, const Offset(0, -1200));
      await tester.pump();
      expect(find.textContaining('不可用作密码或访问令牌'), findsOneWidget);
    });
  });

  testWidgets('三个扩展页面适配窄屏、大字体和横屏', (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    for (final size in [const Size(320, 640), const Size(640, 320)]) {
      tester.view.physicalSize = size;
      for (final screen in const <Widget>[
        PasswordGeneratorScreen(),
        TimestampConverterScreen(),
        UuidGeneratorScreen(),
      ]) {
        await tester.pumpWidget(_app(screen, textScale: 2));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.drag(find.byType(ListView).first, const Offset(0, -300));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      }
    }
  });
}
