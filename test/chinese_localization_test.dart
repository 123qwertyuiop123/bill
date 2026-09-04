import 'package:bill/app/toolbox_app.dart';
import 'package:bill/tools/bmi_calculator/bmi_calculator_screen.dart';
import 'package:bill/tools/csv_json_converter/csv_json_converter_logic.dart';
import 'package:bill/tools/jwt_viewer/jwt_viewer_logic.dart';
import 'package:bill/tools/jwt_viewer/jwt_viewer_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('built-in controls stay Chinese on an English system', (
    tester,
  ) async {
    tester.binding.platformDispatcher.localeTestValue = const Locale(
      'en',
      'US',
    );
    addTearDown(tester.binding.platformDispatcher.clearLocaleTestValue);
    // 复用真实应用的本地化配置，但隔离首页文件读取，避免加载动画干扰弹窗测试。
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          final app = const ToolboxApp().build(context) as MaterialApp;
          return MaterialApp(
            locale: app.locale,
            supportedLocales: app.supportedLocales,
            localizationsDelegates: app.localizationsDelegates,
            home: const Scaffold(),
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(Navigator).first);
    expect(Localizations.localeOf(context), const Locale('zh', 'CN'));
    final labels = MaterialLocalizations.of(context);
    expect(labels.copyButtonLabel, '复制');
    expect(labels.pasteButtonLabel, '粘贴');
    expect(labels.selectAllButtonLabel, '全选');
    expect(labels.backButtonTooltip, '返回');
    expect(CupertinoLocalizations.of(context).copyButtonLabel, '复制');

    final date = showDatePicker(
      context: context,
      initialDate: DateTime(2026, 9, 2),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    await tester.pumpAndSettle();
    expect(find.text('选择日期'), findsOneWidget);
    expect(find.text('取消'), findsOneWidget);
    expect(find.text('确定'), findsOneWidget);
    expect(find.text('CANCEL'), findsNothing);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(await date, isNull);

    final time = showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('选择时间'), findsOneWidget);
    expect(find.text('确定'), findsOneWidget);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(await time, isNull);
  });

  testWidgets('JWT tabs are Chinese without translating the parsed data', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: JwtViewerScreen()));
    expect(find.text('JWT 令牌'), findsOneWidget);
    expect(find.text('头部'), findsOneWidget);
    expect(find.text('载荷'), findsOneWidget);
    expect(find.text('Header'), findsNothing);
    expect(find.text('Payload'), findsNothing);
    await tester.tap(find.text('解析'));
    await tester.pump();
    final output = tester.widget<TextField>(find.byKey(const Key('jwtOutput')));
    expect(output.controller!.text, contains('"sub"'));
    await tester.tap(find.text('头部'));
    await tester.pump();
    expect(output.controller!.text, contains('"alg"'));
    expect(find.text('头部内容（JSON）'), findsOneWidget);
  });

  testWidgets('BMI units use Chinese labels', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: BmiCalculatorScreen()));
    expect(find.text('厘米'), findsOneWidget);
    expect(find.text('千克'), findsOneWidget);
  });

  test('malformed JSON and JWT return Chinese messages without raw input', () {
    final result = convertCsvJson('{private_invalid', CsvJsonMode.jsonToCsv);
    expect(result.error, 'JSON 格式无效，请检查括号、引号和逗号');
    expect(result.error, isNot(contains('private_invalid')));
    expect(parseJwtForViewing('').error, '请输入 JWT 令牌');
    expect(parseJwtForViewing('a.b').error, 'JWT 应包含头部、载荷和签名三段');
  });
}
