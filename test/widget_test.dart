import 'package:bill/expense_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats amounts for the monthly text file', () {
    expect(formatAmount(20), '20');
    expect(formatAmount(9.9), '9.9');
    expect(formatAmount(12.65), '12.65');
    expect(formatTxtAmount(TransactionType.expense, 18.8), '18.8');
    expect(formatTxtAmount(TransactionType.income, 6200), '+6200');
  });

  test('uses the default monthly expense filename', () {
    expect(defaultMonthFileName(DateTime(2026, 8)), '2026年8月消费.txt');
  });

  test('writes one line per day and separates entries with commas', () {
    final records = [
      ExpenseRecord(
        id: '1',
        reason: '午饭',
        amount: 18.8,
        date: DateTime(2026, 8, 1),
        type: TransactionType.expense,
        category: TransactionCategory.food,
      ),
      ExpenseRecord(
        id: '2',
        reason: '工资',
        amount: 6200,
        date: DateTime(2026, 8, 1),
        type: TransactionType.income,
        category: TransactionCategory.salary,
      ),
      ExpenseRecord(
        id: '3',
        reason: '公交',
        amount: 2,
        date: DateTime(2026, 8, 2),
        type: TransactionType.expense,
        category: TransactionCategory.transport,
      ),
    ];

    expect(
      buildMonthTxt(records, DateTime(2026, 8)),
      '1日:午饭:18.8,工资:+6200\n2日:公交:2',
    );
    expect(
      buildMonthTxt(
        records,
        DateTime(2026, 8),
        lineFormat: LedgerLineFormat.fullDate,
      ),
      '2026年8月1日:午饭:18.8,工资:+6200\n2026年8月2日:公交:2',
    );
  });

  test('normalizes safe custom txt names', () {
    expect(normalizeTxtFileName('家庭账本'), '家庭账本.txt');
    expect(normalizeTxtFileName('  八月收支.TXT  '), '八月收支.txt');
  });

  test('rejects path traversal and reserved file names', () {
    expect(
      () => normalizeTxtFileName('../账本'),
      throwsA(isA<ExpenseStorageException>()),
    );
    expect(
      () => normalizeTxtFileName(r'a\b'),
      throwsA(isA<ExpenseStorageException>()),
    );
    expect(
      () => normalizeTxtFileName('CON'),
      throwsA(isA<ExpenseStorageException>()),
    );
    expect(
      () => normalizeTxtFileName('CON.backup'),
      throwsA(isA<ExpenseStorageException>()),
    );
    expect(
      () => normalizeTxtFileName(''),
      throwsA(isA<ExpenseStorageException>()),
    );
  });

  test('expense records can be saved as JSON and restored', () {
    final record = ExpenseRecord(
      id: '1',
      reason: '午饭',
      amount: 9.9,
      date: DateTime(2026, 8, 29),
      type: TransactionType.expense,
      category: TransactionCategory.food,
    );
    final restored = ExpenseRecord.tryFromJson(record.toJson());
    expect(restored?.reason, '午饭');
    expect(restored?.amount, 9.9);
    expect(restored?.date, DateTime(2026, 8, 29));
    expect(restored?.type, TransactionType.expense);
    expect(restored?.category, TransactionCategory.food);
  });

  test('old data without a type remains an expense', () {
    final restored = ExpenseRecord.tryFromJson({
      'id': 'old-1',
      'reason': '公交',
      'amount': 2,
      'date': '2026-08-30',
      'category': 'transport',
    });
    expect(restored?.type, TransactionType.expense);
    expect(restored?.category, TransactionCategory.transport);
  });

  test('income category is restored only for income records', () {
    final restored = ExpenseRecord.tryFromJson({
      'id': 'income-1',
      'reason': '工资',
      'amount': 6000,
      'date': '2026-08-30',
      'type': 'income',
      'category': 'salary',
    });
    expect(restored?.type, TransactionType.income);
    expect(restored?.category, TransactionCategory.salary);
  });

  test('rejects unsafe or invalid persisted values', () {
    expect(
      ExpenseRecord.tryFromJson({
        'id': '1',
        'reason': '',
        'amount': -1,
        'date': 'not-a-date',
      }),
      isNull,
    );
    expect(
      ExpenseRecord.tryFromJson({
        'id': '1',
        'reason': 'x' * 41,
        'amount': 10,
        'date': '2026-08-30',
      }),
      isNull,
    );
  });
}
