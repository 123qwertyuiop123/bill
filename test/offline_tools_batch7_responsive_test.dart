import 'package:bill/core/app_theme.dart';
import 'package:bill/tools/tool_registry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

const _toolIds = [
  'totp_generator',
  'ohms_law_calculator',
  'statistics_calculator',
  'roman_numeral_converter',
];

Widget _app(String id) => MaterialApp(
  theme: buildAppTheme(),
  locale: const Locale('zh', 'CN'),
  supportedLocales: const [Locale('zh', 'CN')],
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context)
        .copyWith(textScaler: const TextScaler.linear(2)),
    child: child!,
  ),
  home: Builder(
    builder: (context) => ToolRegistry.tools
        .singleWhere((tool) => tool.id == id)
        .builder(context),
  ),
);

void main() {
  for (final id in _toolIds) {
    testWidgets('$id remains scrollable on narrow and landscape screens', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      for (final size in [const Size(320, 640), const Size(640, 320)]) {
        tester.view.physicalSize = size;
        await tester.pumpWidget(_app(id));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        final action = find.byType(FilledButton);
        final scrollable = find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first;
        await tester.scrollUntilVisible(action, 120, scrollable: scrollable);
        await tester.pumpAndSettle();
        expect(action.hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(const SizedBox.shrink());
      }
    });
  }
}
