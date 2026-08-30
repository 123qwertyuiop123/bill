import 'package:bill/expense_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats amounts for the monthly text file', () {
    expect(formatAmount(20), '20');
    expect(formatAmount(9.9), '9.9');
    expect(formatAmount(12.65), '12.65');
  });

  test('expense records can be saved as JSON and restored', () {
    final record = ExpenseRecord(
      id: '1',
      reason: '午饭',
      amount: 9.9,
      date: DateTime(2026, 8, 29),
    );
    final restored = ExpenseRecord.fromJson(record.toJson());
    expect(restored.reason, '午饭');
    expect(restored.amount, 9.9);
    expect(restored.date, DateTime(2026, 8, 29));
  });
}
