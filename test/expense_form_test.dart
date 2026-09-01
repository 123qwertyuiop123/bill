import 'package:bill/tools/expense/models/transaction_type.dart';
import 'package:bill/tools/expense/widgets/expense_form_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('switches to text-only income categories', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ExpenseFormSheet())),
    );

    await tester.tap(find.text('收入'));
    await tester.pump();

    expect(find.text('收入种类'), findsOneWidget);
    expect(find.text('工资'), findsOneWidget);
    expect(find.text('奖金'), findsOneWidget);
    expect(find.byIcon(Icons.restaurant_outlined), findsNothing);
    expect(find.byIcon(Icons.account_balance_wallet_outlined), findsNothing);
    expect(TransactionType.income.label, '收入');
  });
}
