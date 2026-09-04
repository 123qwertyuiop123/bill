import 'package:bill/app/widgets/tool_result_widgets.dart';
import 'package:bill/core/app_theme.dart';
import 'package:bill/tools/tool_registry.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

const _ids = [
  'placeholder_text',
  'ipv4_subnet',
  'chmod_calculator',
  'luhn_checker',
];

Widget _app(String id, {double scale = 1}) => MaterialApp(
  theme: buildAppTheme(),
  locale: const Locale('zh', 'CN'),
  supportedLocales: const [Locale('zh', 'CN')],
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: Builder(
    builder: (context) =>
        ToolRegistry.tools.singleWhere((t) => t.id == id).builder(context),
  ),
);

void main() {
  for (final id in _ids) {
    testWidgets(
      '$id remains usable on narrow and landscape screens with large text',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        for (final size in [const Size(320, 640), const Size(640, 320)]) {
          tester.view.physicalSize = size;
          await tester.pumpWidget(_app(id, scale: 2));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          if (id == 'luhn_checker') {
            await tester.enterText(find.byType(TextField), '9' * 128);
          }
          final actions = {
            'placeholder_text': '生成文本',
            'ipv4_subnet': '计算子网',
            'luhn_checker': '开始校验',
          };
          if (actions.containsKey(id)) {
            final button = find.widgetWithText(FilledButton, actions[id]!);
            await tester.scrollUntilVisible(
              button,
              150,
              scrollable: find
                  .descendant(
                    of: find.byType(ListView),
                    matching: find.byType(Scrollable),
                  )
                  .first,
            );
            await tester.pumpAndSettle();
            expect(button.hitTestable(), findsOneWidget);
            await tester.tap(button);
            await tester.pumpAndSettle();
          }
          // ListView 惰性构建屏幕外组件，先滚动创建，再断言可见性。
          await tester.scrollUntilVisible(
            find.byType(CopyResultButton),
            150,
            scrollable: find
                .descendant(
                  of: find.byType(ListView),
                  matching: find.byType(Scrollable),
                )
                .first,
          );
          await tester.pumpAndSettle();
          expect(
            tester.widget<CopyResultButton>(find.byType(CopyResultButton)).text,
            isNotEmpty,
          );
          expect(tester.takeException(), isNull);
          // 每种尺寸从新状态启动，排除前一次滚动位置造成的干扰。
          await tester.pumpWidget(const SizedBox());
        }
      },
    );
  }

  testWidgets(
    'oversized pasted input is not silently truncated into a valid result',
    (tester) async {
      for (final id in _ids) {
        await tester.pumpWidget(_app(id));
        final value = switch (id) {
          'placeholder_text' => '100',
          'ipv4_subnet' => '1' * 65,
          'chmod_calculator' => '0755',
          _ => '0' * 129,
        };
        await tester.enterText(find.byType(TextField).first, value);
        await tester.pump();
        expect(
          tester
              .widget<TextField>(find.byType(TextField).first)
              .controller!
              .text,
          value,
        );
        if (id != 'chmod_calculator') {
          await tester.ensureVisible(find.byType(FilledButton));
          await tester.tap(find.byType(FilledButton));
          await tester.pump();
        }
        expect(
          tester.widget<CopyResultButton>(find.byType(CopyResultButton)).text,
          isEmpty,
        );
        await tester.pumpWidget(const SizedBox());
      }
    },
  );

  testWidgets('copy only runs on tap and reports platform failure safely', (
    tester,
  ) async {
    final calls = <MethodCall>[];
    var fail = false;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          calls.add(call);
          if (fail) throw PlatformException(code: 'private_platform_error');
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: CopyResultButton(text: '本地结果')),
      ),
    );
    expect(calls, isEmpty);
    await tester.tap(find.text('复制结果'));
    await tester.pumpAndSettle();
    expect(calls.single.arguments, {'text': '本地结果'});
    expect(find.text('已复制'), findsOneWidget);
    fail = true;
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.tap(find.text('复制结果'));
    await tester.pumpAndSettle();
    expect(find.text('复制失败，请重试'), findsOneWidget);
    expect(find.textContaining('private_platform_error'), findsNothing);
  });
}
