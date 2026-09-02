import 'package:bill/tools/calculator/calculator_screen.dart';
import 'package:bill/tools/tool_registry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tool registry uses unique stable ids', () {
    final ids = ToolRegistry.tools.map((tool) => tool.id).toList();
    expect(ToolRegistry.tools, hasLength(28));
    expect(ids.toSet(), hasLength(ids.length));
    expect(ids, contains('expense'));
    expect(ids, contains('json_tool'));
    expect(ids, contains('base64_tool'));
    expect(ids, contains('url_tool'));
    expect(ids, contains('timestamp_converter'));
    expect(ids, contains('number_base_converter'));
    expect(ids, contains('uuid_generator'));
    expect(ids, contains('regex_tester'));
    expect(ids, contains('hash_generator'));
    expect(ids, contains('color_contrast'));
    expect(ids, contains('jwt_viewer'));
    expect(ids, contains('csv_json_converter'));
    expect(ids, contains('cron_parser'));
  });

  testWidgets('calculator performs basic arithmetic without evaluating code', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: CalculatorScreen()));

    await tester.tap(find.text('7'));
    await tester.tap(find.text('+'));
    await tester.tap(find.text('8'));
    await tester.ensureVisible(find.text('='));
    await tester.tap(find.text('='));
    await tester.pump();

    expect(find.text('15'), findsOneWidget);
  });
}
