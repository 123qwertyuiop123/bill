import 'package:bill/tools/expense/controllers/expense_controller.dart';
import 'package:bill/tools/expense/models/expense_record.dart';
import 'package:bill/tools/expense/models/ledger_file.dart';
import 'package:bill/tools/expense/models/transaction_category.dart';
import 'package:bill/tools/expense/models/transaction_type.dart';
import 'package:bill/tools/expense/services/expense_storage.dart';
import 'package:bill/tools/expense/services/public_export_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryStorage extends ExpenseStorage {
  final values = <ExpenseRecord>[];
  final writtenMonths = <DateTime>[];
  String customName = '';
  final files = <LedgerFile>[
    const LedgerFile(id: LedgerFile.defaultId, fileName: '默认.txt'),
  ];

  @override
  Future<List<ExpenseRecord>> load() async => List.of(values);

  @override
  Future<void> save(List<ExpenseRecord> records) async {
    values
      ..clear()
      ..addAll(records);
  }

  @override
  Future<List<LedgerFile>> listMonthFiles(DateTime month) async =>
      List.of(files);

  @override
  Future<String> monthFilePath(
    DateTime month, {
    String fileId = LedgerFile.defaultId,
  }) async {
    final file = files.firstWhere((item) => item.id == fileId);
    return '消费记录/${file.fileName}';
  }

  @override
  Future<String> writeMonth(
    List<ExpenseRecord> records,
    DateTime month, {
    String fileId = LedgerFile.defaultId,
  }) {
    writtenMonths.add(DateTime(month.year, month.month));
    return monthFilePath(month, fileId: fileId);
  }

  @override
  Future<LedgerFile> createMonthFile(
    List<ExpenseRecord> records,
    DateTime month,
    String requestedName,
  ) async {
    final created = LedgerFile(
      id: 'extra-${files.length}',
      fileName: normalizeTxtFileName(requestedName),
    );
    files.add(created);
    return created;
  }

  @override
  Future<void> setMonthFileLineFormat(
    DateTime month,
    String fileId,
    LedgerLineFormat format,
  ) async {
    final index = files.indexWhere((item) => item.id == fileId);
    files[index] = files[index].copyWith(lineFormat: format);
  }

  @override
  Future<String> renameMonthFile(
    List<ExpenseRecord> records,
    DateTime month,
    String requestedName, {
    String fileId = LedgerFile.defaultId,
  }) async {
    customName = normalizeTxtFileName(requestedName);
    final index = files.indexWhere((item) => item.id == fileId);
    files[index] = files[index].copyWith(fileName: customName);
    return '消费记录/$customName';
  }
}

class _MemoryExportService extends PublicExportService {
  final syncedYears = <int>[];

  @override
  Future<String?> syncTxt(
    String trustedInternalPath, {
    required int year,
    String? previousFileName,
  }) async {
    syncedYears.add(year);
    final name = trustedInternalPath.split('/').last;
    return '/storage/emulated/0/Download/bill/$year/$name';
  }
}

void main() {
  test('calculates income, expense and balance independently', () async {
    final storage = _MemoryStorage();
    final exporter = _MemoryExportService();
    final controller = ExpenseController(
      storage: storage,
      exportService: exporter,
    );
    await controller.initialize();

    await controller.add(
      ExpenseRecord(
        id: 'income',
        reason: '工资',
        amount: 6200,
        date: DateTime.now(),
        type: TransactionType.income,
        category: TransactionCategory.salary,
      ),
    );
    await controller.add(
      ExpenseRecord(
        id: 'expense',
        reason: '午饭',
        amount: 18.8,
        date: DateTime.now(),
        type: TransactionType.expense,
        category: TransactionCategory.food,
      ),
    );

    expect(controller.incomeTotal, 6200);
    expect(controller.expenseTotal, 18.8);
    expect(controller.balance, 6181.2);
    expect(controller.publicPath, contains('/Download/bill/'));
    expect(exporter.syncedYears, contains(DateTime.now().year));
    expect(
      controller.categoryTotals(
        TransactionType.income,
      )[TransactionCategory.salary],
      6200,
    );
  });

  test('controller keeps the custom monthly filename', () async {
    final storage = _MemoryStorage();
    final controller = ExpenseController(
      storage: storage,
      exportService: _MemoryExportService(),
    );
    await controller.initialize();

    expect(await controller.renameMonthFile('家庭账本'), isTrue);
    expect(controller.filePath, '消费记录/家庭账本.txt');
    expect(storage.customName, '家庭账本.txt');
  });

  test('creates, switches and isolates multiple txt files', () async {
    final storage = _MemoryStorage();
    final controller = ExpenseController(
      storage: storage,
      exportService: _MemoryExportService(),
    );
    await controller.initialize();

    expect(await controller.createMonthFile('家庭'), isTrue);
    final familyId = controller.selectedFileId;
    expect(familyId, isNot(LedgerFile.defaultId));

    await controller.add(
      ExpenseRecord(
        id: 'family-expense',
        reason: '晚饭',
        amount: 30,
        date: DateTime.now(),
        type: TransactionType.expense,
        category: TransactionCategory.food,
      ),
    );
    expect(controller.monthRecords, hasLength(1));

    await controller.selectMonthFile(LedgerFile.defaultId);
    expect(controller.monthRecords, isEmpty);
    await controller.selectMonthFile(familyId);
    expect(controller.monthRecords.single.reason, '晚饭');

    expect(
      await controller.setSelectedFileLineFormat(LedgerLineFormat.fullDate),
      isTrue,
    );
    expect(controller.selectedFile?.lineFormat, LedgerLineFormat.fullDate);
  });

  test('only regenerates months affected by a new record', () async {
    final storage = _MemoryStorage();
    final controller = ExpenseController(
      storage: storage,
      exportService: _MemoryExportService(),
    );
    await controller.initialize();
    storage.writtenMonths.clear();

    await controller.add(
      ExpenseRecord(
        id: 'historical',
        reason: '旧记录',
        amount: 10,
        date: DateTime(2024, 3, 1),
        type: TransactionType.expense,
        category: TransactionCategory.food,
      ),
    );

    expect(storage.writtenMonths.toSet(), {DateTime(2024, 3)});
  });
}
