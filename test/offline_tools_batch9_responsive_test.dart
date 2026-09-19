import 'package:bill/core/app_theme.dart';
import 'package:bill/tools/tool_registry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

const _actions = {
  'color_contrast': 'runColorCheck',
  'loan_calculator': 'calculateLoan',
  'qr_code': 'generateCode',
};

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
  for (final id in _actions.keys) {
    testWidgets('$id remains usable on narrow and landscape screens', (
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

        final action = find.byKey(Key(_actions[id]!));
        final scrollable = find
            .descendant(
              of: find.byType(ListView).first,
              matching: find.byType(Scrollable),
            )
            .first;
        await tester.scrollUntilVisible(action, 120, scrollable: scrollable);
        await tester.pumpAndSettle();
        expect(action.hitTestable(), findsOneWidget);
        await tester.tap(action);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        await tester.drag(find.byType(ListView).first, const Offset(0, -500));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      }
    });
  }
}
