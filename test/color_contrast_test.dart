import 'package:bill/tools/color_contrast/color_contrast_logic.dart';
import 'package:bill/tools/color_contrast/color_contrast_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('calculates contrast and validates bounded hex input', () {
    expect(checkColorContrast('#000', '#fff').ratio, closeTo(21, 1e-10));
    expect(checkColorContrast('#777777', '#ffffff').normalAa, false);
    expect(checkColorContrast('#1234567', '#ffffff').error, isNotNull);
    expect(checkColorContrast('transparent', '#ffffff').error, isNotNull);
  });

  test('simulates three color vision types with bounded RGB output', () {
    for (final type in ColorVisionType.values) {
      final result = simulateColorVision('#ff0000', '#00ff00', type);
      expect(result.isSuccess, true);
      for (final color in [
        result.simulatedForeground!,
        result.simulatedBackground!,
      ]) {
        expect(color.red, inInclusiveRange(0, 255));
        expect(color.green, inInclusiveRange(0, 255));
        expect(color.blue, inInclusiveRange(0, 255));
      }
    }
    expect(
      simulateColorVision('', '#ffffff', ColorVisionType.protanopia).error,
      isNotNull,
    );
  });

  test('generates five bounded theme tones and a readable foreground', () {
    final result = generateColorPalette('#197A4A');
    expect(result.isSuccess, true);
    expect(result.tones.map((tone) => tone.tone), [10, 30, 50, 70, 90]);
    expect(result.tones.map((tone) => tone.hex).toSet(), hasLength(5));
    expect(result.tones.every((tone) => parseHexColor(tone.hex) != null), true);
    expect(result.suggestedForeground, anyOf('#000000', '#FFFFFF'));
    expect(result.foregroundContrast, greaterThanOrEqualTo(4.5));
    expect(generateColorPalette('red').isSuccess, false);
  });

  testWidgets('switches to simulation and clears stale result', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ColorContrastScreen()));
    await tester.ensureVisible(find.byKey(const Key('runColorCheck')));
    await tester.tap(find.byKey(const Key('runColorCheck')));
    await tester.pump();
    expect(find.byKey(const Key('contrastRatio')), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, 1000));
    await tester.pumpAndSettle();
    await tester.tap(find.text('色觉模拟'));
    await tester.pump();
    expect(find.byKey(const Key('contrastRatio')), findsNothing);
    await tester.ensureVisible(find.byKey(const Key('runColorCheck')));
    await tester.tap(find.byKey(const Key('runColorCheck')));
    await tester.pump();
    expect(find.text('模拟后颜色'), findsOneWidget);
  });

  testWidgets('oversized pasted colors are rejected without truncation', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ColorContrastScreen()));
    const oversized = '#12345678';
    final input = find.byKey(const Key('foregroundColorInput'));

    await tester.enterText(input, oversized);
    await tester.pump();
    expect(tester.widget<TextField>(input).controller!.text, oversized);
    await tester.ensureVisible(find.byKey(const Key('runColorCheck')));
    await tester.tap(find.byKey(const Key('runColorCheck')));
    await tester.pump();
    expect(find.text('请输入 #RGB 或 #RRGGBB 格式的颜色'), findsOneWidget);
  });

  testWidgets('theme palette mode renders copyable tone cards', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ColorContrastScreen()));
    await tester.tap(find.text('主题色阶'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('runColorCheck')));
    await tester.tap(find.byKey(const Key('runColorCheck')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('paletteResult')), findsOneWidget);
    expect(find.text('建议前景色'), findsOneWidget);
    expect(find.textContaining('#'), findsWidgets);
  });
}
