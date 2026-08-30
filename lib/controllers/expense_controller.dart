import 'package:flutter/foundation.dart';

import '../models/expense_record.dart';
import '../models/ledger_file.dart';
import '../models/transaction_category.dart';
import '../models/transaction_type.dart';
import '../services/expense_storage.dart';
import '../services/public_export_service.dart';

/// 账本唯一状态入口。页面只负责展示，所有增删改和落盘都经过这里。
class ExpenseController extends ChangeNotifier {
  ExpenseController({
    ExpenseStorage? storage,
    PublicExportService? exportService,
  }) : _storage = storage ?? ExpenseStorage(),
       _exportService = exportService ?? PublicExportService();

  final ExpenseStorage _storage;
  final PublicExportService _exportService;
  final List<ExpenseRecord> _records = [];
  List<LedgerFile> _monthFiles = const [];
  String _selectedFileId = LedgerFile.defaultId;
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  bool _loading = true;
  bool _saving = false;
  String? _error;
  String _filePath = '';
  String _publicPath = '';
  String? _publicSyncError;

  List<ExpenseRecord> get records => List.unmodifiable(_records);
  List<LedgerFile> get monthFiles => List.unmodifiable(_monthFiles);
  String get selectedFileId => _selectedFileId;
  LedgerFile? get selectedFile =>
      _monthFiles.where((item) => item.id == _selectedFileId).firstOrNull;
  DateTime get month => _month;
  bool get loading => _loading;
  bool get saving => _saving;
  String? get error => _error;
  String get filePath => _filePath;
  String get publicPath => _publicPath;
  String? get publicSyncError => _publicSyncError;

  List<ExpenseRecord> get monthRecords =>
      _records
          .where(
            (item) =>
                item.date.year == _month.year &&
                item.date.month == _month.month &&
                item.ledgerFileId == _selectedFileId,
          )
          .toList()
        ..sort((a, b) {
          final date = b.date.compareTo(a.date);
          return date != 0 ? date : b.id.compareTo(a.id);
        });

  double get incomeTotal => monthRecords
      .where((item) => item.type == TransactionType.income)
      .fold(0, (sum, item) => sum + item.amount);

  double get expenseTotal => monthRecords
      .where((item) => item.type == TransactionType.expense)
      .fold(0, (sum, item) => sum + item.amount);

  double get balance => incomeTotal - expenseTotal;

  Map<TransactionCategory, double> categoryTotals(TransactionType type) {
    final result = {
      for (final category in TransactionCategory.forType(type)) category: 0.0,
    };
    for (final item in monthRecords) {
      if (item.type == type) {
        result[item.category] = result[item.category]! + item.amount;
      }
    }
    return result;
  }

  List<ExpenseRecord> recordsForDay(DateTime day) =>
      _records
          .where(
            (item) =>
                _sameDay(item.date, day) &&
                item.ledgerFileId == _selectedFileId,
          )
          .toList()
        ..sort((a, b) => b.id.compareTo(a.id));

  Future<void> initialize() async {
    try {
      _records
        ..clear()
        ..addAll(await _storage.load());
      await _storage.save(_records);
      await _refreshMonthFiles();
      _filePath = await _storage.monthFilePath(_month, fileId: _selectedFileId);
      await _syncAllMonthFiles();
    } on ExpenseStorageException catch (exception) {
      _error = exception.message;
    } on PublicExportException catch (exception) {
      // 公共副本失败不影响应用内部主账本的读取。
      _publicSyncError = exception.message;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> changeMonth(int offset) async {
    final next = DateTime(_month.year, _month.month + offset);
    // 限制可浏览年份，避免极端月份导致日期溢出或生成异常文件名。
    if (next.year < 2000 || next.year > 2100) return;
    _month = next;
    _selectedFileId = LedgerFile.defaultId;
    try {
      await _refreshMonthFiles();
      _filePath = await _storage.writeMonth(
        _records,
        _month,
        fileId: _selectedFileId,
      );
      await _syncMonth(
        _month,
        fileId: _selectedFileId,
        existingPath: _filePath,
      );
    } on ExpenseStorageException catch (exception) {
      _error = exception.message;
    } on PublicExportException catch (exception) {
      _publicSyncError = exception.message;
    }
    notifyListeners();
  }

  Future<bool> renameMonthFile(String name) async {
    if (_saving) {
      _error = '正在保存记录，请稍后再修改文件名';
      notifyListeners();
      return false;
    }
    _saving = true;
    _error = null;
    notifyListeners();
    final oldFileName = _filePath.split(RegExp(r'[/\\]')).last;
    try {
      _filePath = await _storage.renameMonthFile(
        _records,
        _month,
        name,
        fileId: _selectedFileId,
      );
      await _refreshMonthFiles();
      await _syncMonth(
        _month,
        fileId: _selectedFileId,
        existingPath: _filePath,
        previousFileName: oldFileName,
      );
      return true;
    } on ExpenseStorageException catch (exception) {
      _error = exception.message;
      return false;
    } on PublicExportException catch (exception) {
      // 改名已在内部完成；公共副本可在下次启动或记账时再次同步。
      _publicSyncError = exception.message;
      return true;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  Future<bool> createMonthFile(String name) async {
    if (_saving) return false;
    _saving = true;
    _error = null;
    notifyListeners();
    try {
      final created = await _storage.createMonthFile(_records, _month, name);
      _selectedFileId = created.id;
      await _refreshMonthFiles();
      _filePath = await _storage.monthFilePath(_month, fileId: _selectedFileId);
      try {
        await _syncMonth(
          _month,
          fileId: _selectedFileId,
          existingPath: _filePath,
        );
      } on PublicExportException catch (exception) {
        _publicSyncError = exception.message;
      }
      return true;
    } on ExpenseStorageException catch (exception) {
      _error = exception.message;
      return false;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  Future<void> selectMonthFile(String fileId) async {
    if (_saving || !_monthFiles.any((item) => item.id == fileId)) return;
    _selectedFileId = fileId;
    try {
      _filePath = await _storage.writeMonth(_records, _month, fileId: fileId);
      await _syncMonth(_month, fileId: fileId, existingPath: _filePath);
    } on ExpenseStorageException catch (exception) {
      _error = exception.message;
    } on PublicExportException catch (exception) {
      _publicSyncError = exception.message;
    }
    notifyListeners();
  }

  Future<bool> setSelectedFileLineFormat(LedgerLineFormat format) async {
    if (_saving || selectedFile?.lineFormat == format) return !_saving;
    _saving = true;
    _error = null;
    notifyListeners();
    try {
      await _storage.setMonthFileLineFormat(_month, _selectedFileId, format);
      await _refreshMonthFiles();
      _filePath = await _storage.writeMonth(
        _records,
        _month,
        fileId: _selectedFileId,
      );
      try {
        await _syncMonth(
          _month,
          fileId: _selectedFileId,
          existingPath: _filePath,
        );
      } on PublicExportException catch (exception) {
        _publicSyncError = exception.message;
      }
      return true;
    } on ExpenseStorageException catch (exception) {
      _error = exception.message;
      return false;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  Future<bool> add(ExpenseRecord record) async {
    final sameMonth =
        record.date.year == _month.year && record.date.month == _month.month;
    final targetFileId = sameMonth ? _selectedFileId : LedgerFile.defaultId;
    final assigned = record.copyWith(ledgerFileId: targetFileId);
    _records.add(assigned);
    final success = await _persist(rollback: () => _records.remove(assigned));
    if (success) {
      _month = DateTime(record.date.year, record.date.month);
      _selectedFileId = targetFileId;
      await _refreshMonthFiles();
      _filePath = await _storage.monthFilePath(_month, fileId: _selectedFileId);
      final fileName = _filePath.split(RegExp(r'[/\\]')).last;
      _publicPath = expectedPublicTxtPath(_month, fileName);
      notifyListeners();
    }
    return success;
  }

  Future<bool> update(ExpenseRecord changed) async {
    final index = _records.indexWhere((item) => item.id == changed.id);
    if (index < 0) return false;
    final original = _records[index];
    final movedToAnotherMonth =
        original.date.year != changed.date.year ||
        original.date.month != changed.date.month;
    final storedChange = movedToAnotherMonth
        ? changed.copyWith(ledgerFileId: LedgerFile.defaultId)
        : changed;
    _records[index] = storedChange;
    return _persist(
      rollback: () => _records[index] = original,
      additionalMonths: [DateTime(original.date.year, original.date.month)],
    );
  }

  Future<bool> remove(ExpenseRecord record) async {
    final index = _records.indexWhere((item) => item.id == record.id);
    if (index < 0) return false;
    _records.removeAt(index);
    return _persist(
      rollback: () => _records.insert(index, record),
      additionalMonths: [DateTime(record.date.year, record.date.month)],
    );
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<bool> _persist({
    required VoidCallback rollback,
    Iterable<DateTime> additionalMonths = const [],
  }) async {
    if (_saving) {
      rollback();
      _error = '正在保存上一笔记录，请稍后再试';
      notifyListeners();
      return false;
    }
    _saving = true;
    _error = null;
    notifyListeners();
    try {
      await _storage.save(_records);
      try {
        await _syncAllMonthFiles(additionalMonths: additionalMonths);
      } on PublicExportException catch (exception) {
        // 同步公共副本失败时不回滚已经安全保存的账本数据。
        _publicSyncError = exception.message;
      }
      return true;
    } on ExpenseStorageException catch (exception) {
      rollback();
      _error = exception.message;
      return false;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _syncAllMonthFiles({
    Iterable<DateTime> additionalMonths = const [],
  }) async {
    final months = <DateTime>{
      DateTime(DateTime.now().year, DateTime.now().month),
      for (final item in _records) DateTime(item.date.year, item.date.month),
      for (final month in additionalMonths) DateTime(month.year, month.month),
    };
    for (final month in months) {
      for (final ledgerFile in await _storage.listMonthFiles(month)) {
        await _syncMonth(month, fileId: ledgerFile.id);
      }
    }
    _publicSyncError = null;
  }

  Future<void> _syncMonth(
    DateTime month, {
    required String fileId,
    String? existingPath,
    String? previousFileName,
  }) async {
    final internalPath =
        existingPath ??
        await _storage.writeMonth(_records, month, fileId: fileId);
    final fileName = internalPath.split(RegExp(r'[/\\]')).last;
    final savedPath = await _exportService.syncTxt(
      internalPath,
      year: month.year,
      previousFileName: previousFileName,
    );
    if (month.year == _month.year &&
        month.month == _month.month &&
        fileId == _selectedFileId) {
      _publicPath = savedPath ?? expectedPublicTxtPath(month, fileName);
    }
    _publicSyncError = null;
  }

  Future<void> _refreshMonthFiles() async {
    _monthFiles = await _storage.listMonthFiles(_month);
    if (!_monthFiles.any((item) => item.id == _selectedFileId)) {
      _selectedFileId = LedgerFile.defaultId;
    }
  }
}
