import 'package:bill/tools/calculator/calculator_screen.dart';
import 'package:bill/tools/tool_registry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tool registry uses unique stable ids', () {
    final ids = ToolRegistry.tools.map((tool) => tool.id).toList();
    expect(ToolRegistry.tools, hasLength(16));
    expect(ids.toSet(), hasLength(ids.length));
    expect(ids, contains('expense'));
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
