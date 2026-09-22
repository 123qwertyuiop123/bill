import 'package:bill/core/app_theme.dart';
import 'package:bill/tools/color_contrast/color_contrast_screen.dart';
import 'package:bill/tools/image_optimizer/image_optimizer_screen.dart';
import 'package:bill/tools/image_optimizer/services/image_optimizer_service.dart';
import 'package:bill/tools/url_tool/url_tool_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

class _PrivacyImageService extends ImageOptimizerService {
  const _PrivacyImageService();

  @override
  Future<SelectedImageInfo?> pickImage() async => const SelectedImageInfo(
    name: '隐私检查.jpg',
    size: 1024,
    width: 800,
    height: 600,
  );

  @override
  Future<ImagePrivacyInfo> inspectMetadata() async => const ImagePrivacyInfo(
    hasCaptureTime: false,
    hasDeviceInfo: false,
    hasLocation: false,
    orientation: 'normal',
  );
}

Widget _app(Widget home) => MaterialApp(
  theme: buildAppTheme(),
  locale: const Locale('zh', 'CN'),
  supportedLocales: const [Locale('zh', 'CN')],
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context)
        .copyWith(textScaler: const TextScaler.linear(2)),
    child: child!,
  ),
  home: home,
);

Finder _verticalScrollable() => find
    .descendant(
      of: find.byType(ListView).first,
      matching: find.byType(Scrollable),
    )
    .first;

Future<void> _scrollToAndTap(WidgetTester tester, Finder target) async {
  final scrollable = _verticalScrollable();
  await tester.scrollUntilVisible(target, 120, scrollable: scrollable);
  // scrollUntilVisible 在大字体下可能只露出按钮边缘，再滚动一段以确保按钮中心可点击。
  await tester.drag(scrollable, const Offset(0, -100));
  await tester.pumpAndSettle();
  await tester.tap(target);
}

void main() {
  testWidgets('图片隐私检查支持窄屏、横屏和两倍字体', (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    for (final size in [const Size(320, 640), const Size(640, 320)]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        _app(
          ImageOptimizerScreen(
            key: ValueKey(size),
            service: const _PrivacyImageService(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('隐私检查'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('pickImage')));
      await tester.pumpAndSettle();
      final action = find.byKey(const Key('inspectImageMetadata'));
      await _scrollToAndTap(tester, action);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('未发现隐私相关信息'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('国际域名转换支持窄屏、横屏和两倍字体', (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    for (final size in [const Size(320, 640), const Size(640, 320)]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(_app(UrlToolScreen(key: ValueKey(size))));
      await tester.pumpAndSettle();
      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(-360, 0),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('国际域名'));
      await tester.pumpAndSettle();
      final action = find.byKey(const Key('processUrl'));
      await _scrollToAndTap(tester, action);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('xn--h6qv61a4jx.example'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('主题色阶支持窄屏、横屏和两倍字体', (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    for (final size in [const Size(320, 640), const Size(640, 320)]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(_app(ColorContrastScreen(key: ValueKey(size))));
      await tester.pumpAndSettle();
      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(-360, 0),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('主题色阶'));
      await tester.pumpAndSettle();
      final action = find.byKey(const Key('runColorCheck'));
      await _scrollToAndTap(tester, action);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('paletteResult')), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
}
