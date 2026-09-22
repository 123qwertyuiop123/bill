import 'package:bill/tools/image_optimizer/image_optimizer_logic.dart';
import 'package:bill/tools/image_optimizer/image_optimizer_screen.dart';
import 'package:bill/tools/image_optimizer/services/image_optimizer_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeImageOptimizerService extends ImageOptimizerService {
  const _FakeImageOptimizerService();

  @override
  Future<SelectedImageInfo?> pickImage() async => const SelectedImageInfo(
    name: '旅行照片.jpg',
    size: 8600000,
    width: 4032,
    height: 3024,
  );

  @override
  Future<OptimizedImageInfo> optimize({
    required ImageTargetSize target,
    required int quality,
    required ImageOutputFormat format,
  }) async => OptimizedImageInfo(
    size: 1900000,
    width: target.width,
    height: target.height,
  );

  @override
  Future<ImagePrivacyInfo> inspectMetadata() async => const ImagePrivacyInfo(
    hasCaptureTime: true,
    hasDeviceInfo: true,
    hasLocation: true,
    orientation: 'rotate_90',
    captureTime: '2026:09:22 08:30:00',
    cameraModel: '示例相机',
  );

  @override
  Future<String> save() async =>
      '/storage/emulated/0/Pictures/ZM工具箱/旅行照片_optimized.jpg';
}

void main() {
  test('calculates a bounded aspect-preserving image target', () {
    final result = calculateImageTarget(
      widthText: '1920',
      heightText: '1920',
      sourceWidth: 4032,
      sourceHeight: 3024,
      keepAspectRatio: true,
      allowUpscale: false,
    );

    expect(result.width, 1920);
    expect(result.height, 1440);
    expect(imageReductionPercent(1000, 250), 75);
  });

  test('prevents unwanted upscale and rejects invalid targets', () {
    final result = calculateImageTarget(
      widthText: '2000',
      heightText: '2000',
      sourceWidth: 800,
      sourceHeight: 600,
      keepAspectRatio: true,
      allowUpscale: false,
    );
    expect((result.width, result.height), (800, 600));
    expect(
      () => calculateImageTarget(
        widthText: '0',
        heightText: '100',
        sourceWidth: 800,
        sourceHeight: 600,
        keepAspectRatio: true,
        allowUpscale: false,
      ),
      throwsFormatException,
    );
  });

  test('rejects stretching beyond the source when upscale is disabled', () {
    expect(
      () => calculateImageTarget(
        widthText: '900',
        heightText: '600',
        sourceWidth: 800,
        sourceHeight: 600,
        keepAspectRatio: false,
        allowUpscale: false,
      ),
      throwsFormatException,
    );
  });

  testWidgets(
    'selects, optimizes and saves without moving image bytes to Dart',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ImageOptimizerScreen(service: _FakeImageOptimizerService()),
        ),
      );

      await tester.tap(find.byKey(const Key('pickImage')));
      await tester.pumpAndSettle();
      expect(find.text('旅行照片.jpg'), findsOneWidget);
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('optimizeImage')));
      await tester.pumpAndSettle();
      expect(find.text('优化完成'), findsOneWidget);
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('saveOptimizedImage')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Pictures/ZM工具箱'), findsOneWidget);
    },
  );

  testWidgets('does not truncate an oversized target into another size', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ImageOptimizerScreen(service: _FakeImageOptimizerService()),
      ),
    );
    await tester.tap(find.byKey(const Key('pickImage')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '10000');
    await tester.scrollUntilVisible(
      find.byKey(const Key('optimizeImage')),
      300,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.byKey(const Key('optimizeImage')));
    await tester.pump();

    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller?.text,
      '10000',
    );
    expect(find.textContaining('目标宽度必须在'), findsOneWidget);
  });

  testWidgets('inspects only the privacy metadata summary', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ImageOptimizerScreen(service: _FakeImageOptimizerService()),
      ),
    );

    await tester.tap(find.text('隐私检查'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pickImage')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('inspectImageMetadata')));
    await tester.tap(find.byKey(const Key('inspectImageMetadata')));
    await tester.pumpAndSettle();

    expect(find.text('发现隐私相关信息'), findsOneWidget);
    expect(find.text('存在（坐标已隐藏）'), findsOneWidget);
    expect(find.text('旋转 90°'), findsOneWidget);
  });
}
