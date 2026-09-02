import 'dart:io';

import 'package:bill/tools/expense/models/expense_record.dart';
import 'package:bill/tools/expense/models/transaction_category.dart';
import 'package:bill/tools/expense/models/transaction_type.dart';
import 'package:bill/tools/expense/services/expense_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory directory;
  late ExpenseStorage storage;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('bill_capacity_test_');
    storage = ExpenseStorage(folderProvider: () async => directory);
  });

  tearDown(() async {
    if (await directory.exists()) await directory.delete(recursive: true);
  });

  test('rejects a persisted ledger larger than the byte limit', () async {
    final ledgerDirectory = Directory(
      '${directory.path}${Platform.pathSeparator}消费记录',
    );
    await ledgerDirectory.create();
    final data = File(
      '${ledgerDirectory.path}${Platform.pathSeparator}expenses.json',
    );
    await data.writeAsBytes(
      List<int>.filled(ExpenseStorage.maxDataFileBytes + 1, 0),
      flush: true,
    );

    expect(
      storage.load,
      throwsA(
        isA<ExpenseStorageException>().having(
          (error) => error.message,
          'message',
          contains('安全上限'),
        ),
      ),
    );
  });

  test('rejects more than the supported number of records', () async {
    final record = ExpenseRecord(
      id: 'record',
      reason: '测试',
      amount: 1,
      date: DateTime(2026, 9, 1),
      type: TransactionType.expense,
      category: TransactionCategory.food,
    );

    expect(
      () => storage.save(List.filled(ExpenseStorage.maxRecords + 1, record)),
      throwsA(isA<ExpenseStorageException>()),
    );
  });
}
