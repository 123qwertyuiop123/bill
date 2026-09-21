import 'package:bill/core/app_theme.dart';
import 'package:bill/tools/color_contrast/color_contrast_logic.dart';
import 'package:bill/tools/color_contrast/color_contrast_screen.dart';
import 'package:bill/tools/coordinate_tool/coordinate_tool_logic.dart';
import 'package:bill/tools/coordinate_tool/coordinate_tool_screen.dart';
import 'package:bill/tools/tool_registry.dart';
import 'package:bill/tools/unit_converter/unit_converter_logic.dart';
import 'package:bill/tools/unit_converter/unit_converter_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('地理坐标', () {
    test('十进制度与度分秒可以双向转换并校验边界', () {
      final dms = decimalToDms('31.2304', CoordinateAxis.latitude);
      expect(dms.isSuccess, true);
      expect(dms.dms, contains('北纬 31° 13′'));

      final decimal = dmsToDecimal(
        degreesInput: '31',
        minutesInput: '13',
        secondsInput: '49.44',
        axis: CoordinateAxis.latitude,
        hemisphere: '北纬',
      );
      expect(decimal.decimal, closeTo(31.2304, 1e-10));
      expect(decimalToDms('91', CoordinateAxis.latitude).error, isNotNull);
      expect(
        dmsToDecimal(
          degreesInput: '90',
          minutesInput: '1',
          secondsInput: '0',
          axis: CoordinateAxis.latitude,
          hemisphere: '北纬',
        ).error,
        isNotNull,
      );
    });

    test('计算球面距离、方位、反经线和重合点', () {
      final result = calculateCoordinateDistance(
        startLatitude: '31.2304',
        startLongitude: '121.4737',
        endLatitude: '39.9042',
        endLongitude: '116.4074',
      );
      expect(result.isSuccess, true);
      expect(result.distanceKm, closeTo(1067, 3));
      expect(result.initialBearing, inInclusiveRange(325, 340));
      expect(result.direction, '西北');

      final antimeridian = calculateCoordinateDistance(
        startLatitude: '0',
        startLongitude: '179',
        endLatitude: '0',
        endLongitude: '-179',
      );
      expect(antimeridian.distanceKm, closeTo(222.39, 0.2));

      final same = calculateCoordinateDistance(
        startLatitude: '0',
        startLongitude: '0',
        endLatitude: '0',
        endLongitude: '0',
      );
      expect(same.distanceKm, 0);
      expect(same.hasUniqueBearing, false);

      final antipodal = calculateCoordinateDistance(
        startLatitude: '0',
        startLongitude: '0',
        endLatitude: '0',
        endLongitude: '180',
      );
      expect(antipodal.hasUniqueBearing, false);
      expect(antipodal.direction, '对跖点方位不唯一');
    });

    testWidgets('页面可生成转换结果并切换距离模式', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: CoordinateToolScreen()));
      await tester.tap(find.byKey(const Key('calculateCoordinate')));
      await tester.pump();
      expect(
        find.byKey(const Key('coordinateConversionResult')),
        findsOneWidget,
      );

      await tester.tap(find.text('距离方位'));
      await tester.pump();
      await tester.tap(find.byKey(const Key('calculateCoordinate')));
      await tester.pump();
      expect(find.byKey(const Key('coordinateDistanceResult')), findsOneWidget);
    });

    testWidgets('坐标输入不会静默删除单位符号', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: CoordinateToolScreen()));
      final input = find.byType(TextField).first;

      await tester.enterText(input, '31°');
      expect(tester.widget<TextField>(input).controller!.text, '31°');
      await tester.tap(find.byKey(const Key('calculateCoordinate')));
      await tester.pump();
      expect(find.textContaining('必须是有效有限数值'), findsOneWidget);
    });
  });

  group('颜色格式转换', () {
    test('HEX、RGB、HSL 与 HSV 可严格转换', () {
      final hex = convertColorFormat('#197A4A', ColorInputFormat.hex);
      expect(hex.rgb, '25, 122, 74');
      expect(hex.hsl, startsWith('150.31'));
      expect(hex.hsv, startsWith('150.31'));

      expect(
        convertColorFormat('25, 122, 74', ColorInputFormat.rgb).hex,
        '#197A4A',
      );
      expect(
        convertColorFormat('149, 66%, 29%', ColorInputFormat.hsl).isSuccess,
        true,
      );
      expect(
        convertColorFormat('149, 80%, 48%', ColorInputFormat.hsv).isSuccess,
        true,
      );
      expect(
        convertColorFormat('256, 0, 0', ColorInputFormat.rgb).error,
        isNotNull,
      );
      expect(
        convertColorFormat('0, 101%, 20%', ColorInputFormat.hsl).error,
        isNotNull,
      );
      expect(
        convertColorFormat('rgb(100%, 0%, 0%)', ColorInputFormat.rgb).error,
        isNotNull,
      );
      expect(
        convertColorFormat('hsl(149, 66, 29)', ColorInputFormat.hsl).error,
        isNotNull,
      );
      expect(
        convertColorFormat('hsv(149%, 80%, 48%)', ColorInputFormat.hsv).error,
        isNotNull,
      );
      expect(
        convertColorFormat('rgb(25, 122, 74)', ColorInputFormat.rgb).hex,
        '#197A4A',
      );
    });

    testWidgets('格式转换页签显示四种结果', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ColorContrastScreen()));
      await tester.tap(find.text('格式转换'));
      await tester.pump();
      await tester.ensureVisible(find.byKey(const Key('runColorCheck')));
      await tester.tap(find.byKey(const Key('runColorCheck')));
      await tester.pump();
      expect(find.text('#197A4A'), findsWidgets);
      expect(find.text('25, 122, 74'), findsOneWidget);
      expect(find.text('HSL'), findsOneWidget);
      expect(find.text('HSV'), findsOneWidget);
    });
  });

  group('数据容量换算', () {
    test('区分十进制 GB 与二进制 GiB', () {
      final result = convertUnit(
        input: '1',
        kind: '数据容量',
        from: 'GB（十进制）',
        to: 'GiB（二进制）',
      );
      expect(result.value, closeTo(0.9313225746, 1e-10));
      expect(formatUnitValue(result.value!), '0.931322575');
      expect(
        convertUnit(input: 'NaN', kind: '数据容量', from: '字节', to: '比特').error,
        isNotNull,
      );
      expect(
        convertUnit(input: '1', kind: '数据容量', from: '米', to: '字节').error,
        isNotNull,
      );
      expect(
        convertUnit(input: '-1', kind: '数据容量', from: '字节', to: '比特').error,
        '数据容量不能小于 0',
      );
    });

    testWidgets('单位换算仍可完成默认长度换算', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: UnitConverterScreen()));
      await tester.tap(find.byKey(const Key('convertUnit')));
      await tester.pump();
      expect(find.text('0.001 千米'), findsOneWidget);
    });

    testWidgets('单位输入保留非法字符并显示错误', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: UnitConverterScreen()));
      final input = find.byKey(const Key('unitValueInput'));

      await tester.enterText(input, '1,5');
      expect(tester.widget<TextField>(input).controller!.text, '1,5');
      await tester.tap(find.byKey(const Key('convertUnit')));
      await tester.pump();
      expect(find.text('请输入有效的有限数值'), findsOneWidget);

      final oversized = '1' * (maxUnitInputLength + 1);
      await tester.enterText(input, oversized);
      expect(tester.widget<TextField>(input).controller!.text, oversized);
      await tester.tap(find.byKey(const Key('convertUnit')));
      await tester.pump();
      expect(find.text('数值输入不能超过 64 个字符'), findsOneWidget);
    });
  });

  group('第十一批响应式布局', () {
    for (final entry in const {
      'coordinate_tool': 'calculateCoordinate',
      'color_contrast': 'runColorCheck',
      'unit_converter': 'convertUnit',
    }.entries) {
      testWidgets('${entry.key} 支持窄屏、横屏和两倍字体', (tester) async {
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        for (final size in [const Size(320, 640), const Size(640, 320)]) {
          tester.view.physicalSize = size;
          await tester.pumpWidget(
            MaterialApp(
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
                    .singleWhere((tool) => tool.id == entry.key)
                    .builder(context),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final action = find.byKey(Key(entry.value));
          await tester.scrollUntilVisible(
            action,
            100,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.pumpAndSettle();
          expect(action.hitTestable(), findsOneWidget);
          await tester.tap(action);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        }
      });
    }
  });
}
