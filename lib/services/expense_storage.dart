import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:path_provider/path_provider.dart';

import '../models/expense_record.dart';
import '../models/ledger_file.dart';
import '../models/transaction_type.dart';

class ExpenseStorageException implements Exception {
  const ExpenseStorageException(this.message);
  final String message;
  @override
  String toString() => message;
}

class ExpenseStorage {
  static const _folderName = '消费记录';
  static const _dataName = 'expenses.json';
  static const _fileNamesName = 'file_names.json';
  static const _ledgerFilesName = 'ledger_files.json';
  static const _lineFormatsName = 'line_formats.json';

  Future<Directory> get _folder async {
    // ApplicationDocuments 是应用持久化文档目录，系统清理缓存时不会删除。
    // 不使用 getTemporaryDirectory 或 getApplicationCacheDirectory。
    final documents = await getApplicationDocumentsDirectory();
    // 目录名和文件名均为常量，禁止用户输入参与路径拼接，避免路径穿越。
    final folder = Directory(
      '${documents.path}${Platform.pathSeparator}$_folderName',
    );
    if (!await folder.exists()) await folder.create(recursive: true);
    return folder;
  }

  Future<File> get _dataFile async {
    final folder = await _folder;
    return File('${folder.path}${Platform.pathSeparator}$_dataName');
  }

  Future<File> get _fileNamesFile async {
    final folder = await _folder;
    return File('${folder.path}${Platform.pathSeparator}$_fileNamesName');
  }

  Future<File> get _ledgerFilesFile async {
    final folder = await _folder;
    return File('${folder.path}${Platform.pathSeparator}$_ledgerFilesName');
  }

  Future<File> get _lineFormatsFile async {
    final folder = await _folder;
    return File('${folder.path}${Platform.pathSeparator}$_lineFormatsName');
  }

  Future<List<ExpenseRecord>> load() async {
    final file = await _dataFile;
    if (!await file.exists()) return [];
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! List) throw const FormatException('根节点不是数组');
      // 单条损坏数据不会导致整个账本无法启动。
      final records = decoded
          .map(ExpenseRecord.tryFromJson)
          .whereType<ExpenseRecord>()
          .toList();
      // 如果文件列表配置被意外删除或损坏，不隐藏原有记录，而是归回默认 TXT。
      for (var index = 0; index < records.length; index++) {
        final record = records[index];
        if (record.ledgerFileId == LedgerFile.defaultId) continue;
        final files = await listMonthFiles(record.date);
        if (!files.any((item) => item.id == record.ledgerFileId)) {
          records[index] = record.copyWith(ledgerFileId: LedgerFile.defaultId);
        }
      }
      return records;
    } on FormatException catch (_) {
      throw const ExpenseStorageException('账本数据格式损坏，请检查 expenses.json');
    } on FileSystemException catch (_) {
      throw const ExpenseStorageException('无法读取本地账本，请检查文件权限');
    }
  }

  Future<void> save(List<ExpenseRecord> records) async {
    final file = await _dataFile;
    final temp = File('${file.path}.tmp');
    try {
      final content = const JsonEncoder.withIndent('  ').convert(
        records.map((record) => record.toJson()).toList(growable: false),
      );
      // 先完整写入临时文件，再替换正式文件，降低异常中断造成半文件的风险。
      await temp.writeAsString(content, flush: true);
      await file.writeAsBytes(await temp.readAsBytes(), flush: true);
      if (await temp.exists()) await temp.delete();
    } on FileSystemException catch (_) {
      if (await temp.exists()) await temp.delete();
      throw const ExpenseStorageException('保存失败，请检查剩余空间和文件权限');
    }

    final months = <DateTime>{
      DateTime(DateTime.now().year, DateTime.now().month),
      for (final item in records) DateTime(item.date.year, item.date.month),
      ...await _configuredMonths(),
    };
    for (final month in months) {
      for (final ledgerFile in await listMonthFiles(month)) {
        await writeMonth(records, month, fileId: ledgerFile.id);
      }
    }
  }

  Future<String> writeMonth(
    List<ExpenseRecord> records,
    DateTime month, {
    String fileId = LedgerFile.defaultId,
  }) async {
    final safeMonth = DateTime(
      month.year.clamp(2000, 2100),
      month.month.clamp(1, 12),
    );
    final selected = (await listMonthFiles(safeMonth))
        .where((item) => item.id == fileId)
        .firstOrNull;
    if (selected == null) {
      throw const ExpenseStorageException('所选 TXT 文件不存在');
    }
    final folder = await _folder;
    final file = File(
      '${folder.path}${Platform.pathSeparator}${selected.fileName}',
    );
    final text = buildMonthTxt(
      records,
      safeMonth,
      fileId: fileId,
      lineFormat: selected.lineFormat,
    );
    try {
      await file.writeAsString(text, flush: true);
      return file.path;
    } on FileSystemException catch (_) {
      throw const ExpenseStorageException('无法生成月度 TXT 文件');
    }
  }

  Future<String> monthFilePath(
    DateTime month, {
    String fileId = LedgerFile.defaultId,
  }) async {
    final folder = await _folder;
    final files = await listMonthFiles(month);
    final selected = files.where((item) => item.id == fileId).firstOrNull;
    if (selected == null) {
      throw const ExpenseStorageException('所选 TXT 文件不存在');
    }
    final fileName = selected.fileName;
    return '${folder.path}${Platform.pathSeparator}$fileName';
  }

  Future<List<LedgerFile>> listMonthFiles(DateTime month) async {
    final names = await _loadFileNames();
    final configured = await _loadLedgerFiles();
    final formats = await _loadLineFormats();
    return [
      LedgerFile(
        id: LedgerFile.defaultId,
        fileName: names[_monthKey(month)] ?? defaultMonthFileName(month),
        lineFormat:
            formats[_lineFormatKey(month, LedgerFile.defaultId)] ??
            LedgerLineFormat.day,
      ),
      ...configured[_monthKey(month)] ?? const <LedgerFile>[],
    ];
  }

  Future<void> setMonthFileLineFormat(
    DateTime month,
    String fileId,
    LedgerLineFormat format,
  ) async {
    if (fileId == LedgerFile.defaultId) {
      final formats = await _loadLineFormats();
      formats[_lineFormatKey(month, fileId)] = format;
      await _saveLineFormats(formats);
      return;
    }
    final configured = await _loadLedgerFiles();
    final files = configured[_monthKey(month)];
    final index = files?.indexWhere((item) => item.id == fileId);
    if (files == null || index == null || index < 0) {
      throw const ExpenseStorageException('所选 TXT 文件不存在');
    }
    files[index] = files[index].copyWith(lineFormat: format);
    await _saveLedgerFiles(configured);
  }

  /// 为当前月份创建一个独立 TXT；新文件不会共享默认账本里的记录。
  Future<LedgerFile> createMonthFile(
    List<ExpenseRecord> records,
    DateTime month,
    String requestedName,
  ) async {
    final normalized = normalizeTxtFileName(requestedName);
    final existing = await listMonthFiles(month);
    if (existing.any(
      (item) => item.fileName.toLowerCase() == normalized.toLowerCase(),
    )) {
      throw const ExpenseStorageException('该文件名已经存在，请换一个名称');
    }
    final folder = await _folder;
    final diskCollision = await folder.list(followLinks: false).any((entity) {
      if (entity is! File) return false;
      final name = entity.path.split(RegExp(r'[/\\]')).last;
      return name.toLowerCase() == normalized.toLowerCase();
    });
    if (diskCollision) {
      throw const ExpenseStorageException('该文件名已在其他月份使用，请换一个名称');
    }
    final id =
        'file_${DateTime.now().microsecondsSinceEpoch}_${Random.secure().nextInt(1 << 32)}';
    final created = LedgerFile(id: id, fileName: normalized);
    final configured = await _loadLedgerFiles();
    configured.putIfAbsent(_monthKey(month), () => []).add(created);
    await _saveLedgerFiles(configured);
    try {
      await writeMonth(records, month, fileId: id);
      return created;
    } on Object {
      configured[_monthKey(month)]?.removeWhere((item) => item.id == id);
      await _saveLedgerFiles(configured);
      rethrow;
    }
  }

  /// 修改某个月的 TXT 文件名。文件只能在应用的固定目录内重命名。
  Future<String> renameMonthFile(
    List<ExpenseRecord> records,
    DateTime month,
    String requestedName, {
    String fileId = LedgerFile.defaultId,
  }) async {
    final normalized = normalizeTxtFileName(requestedName);
    final folder = await _folder;
    final currentPath = await monthFilePath(month, fileId: fileId);
    final targetPath = '${folder.path}${Platform.pathSeparator}$normalized';
    if (currentPath.toLowerCase() == targetPath.toLowerCase()) {
      return currentPath;
    }

    final current = File(currentPath);
    final target = File(targetPath);
    final collision = await folder.list(followLinks: false).any((entity) {
      if (entity is! File) return false;
      final existingName = entity.path.split(RegExp(r'[/\\]')).last;
      return existingName.toLowerCase() == normalized.toLowerCase();
    });
    if (await target.exists() || collision) {
      throw const ExpenseStorageException('该文件名已经存在，请换一个名称');
    }

    final key = _monthKey(month);
    final names = await _loadFileNames();
    final configured = await _loadLedgerFiles();
    final previousName = fileId == LedgerFile.defaultId
        ? names[key]
        : configured[key]
              ?.where((item) => item.id == fileId)
              .firstOrNull
              ?.fileName;
    try {
      // 先移动已有 TXT，再保存名称配置；配置失败时恢复原文件名。
      if (await current.exists()) await current.rename(targetPath);
      if (fileId == LedgerFile.defaultId) {
        names[key] = normalized;
        await _saveFileNames(names);
      } else {
        final index = configured[key]?.indexWhere((item) => item.id == fileId);
        if (index == null || index < 0) {
          throw const ExpenseStorageException('所选 TXT 文件不存在');
        }
        configured[key]![index] = configured[key]![index].copyWith(
          fileName: normalized,
        );
        await _saveLedgerFiles(configured);
      }
      if (!await target.exists()) {
        await writeMonth(records, month, fileId: fileId);
      }
      return targetPath;
    } on Object catch (error) {
      try {
        if (await target.exists() && !await current.exists()) {
          await target.rename(currentPath);
        }
      } on FileSystemException {
        // 保留原异常信息；下次启动仍可从固定目录读取现有文件。
      }
      if (fileId == LedgerFile.defaultId) {
        if (previousName == null) {
          names.remove(key);
        } else {
          names[key] = previousName;
        }
        try {
          await _saveFileNames(names);
        } on ExpenseStorageException {
          // 回滚配置失败时不覆盖最初错误。
        }
      } else {
        final index = configured[key]?.indexWhere((item) => item.id == fileId);
        if (index != null && index >= 0 && previousName != null) {
          configured[key]![index] = configured[key]![index].copyWith(
            fileName: previousName,
          );
          try {
            await _saveLedgerFiles(configured);
          } on ExpenseStorageException {
            // 回滚配置失败时不覆盖最初错误。
          }
        }
      }
      if (error is ExpenseStorageException) rethrow;
      throw const ExpenseStorageException('无法修改文件名，请检查文件是否被占用');
    }
  }

  Future<Map<String, String>> _loadFileNames() async {
    final file = await _fileNamesFile;
    if (!await file.exists()) return {};
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map<String, dynamic>) return {};
      final result = <String, String>{};
      for (final entry in decoded.entries) {
        if (entry.value is! String) continue;
        try {
          result[entry.key] = normalizeTxtFileName(entry.value as String);
        } on ExpenseStorageException {
          // 忽略被手动篡改或已经不合法的名称配置。
        }
      }
      return result;
    } on FormatException {
      return {};
    } on FileSystemException {
      throw const ExpenseStorageException('无法读取自定义文件名配置');
    }
  }

  Future<void> _saveFileNames(Map<String, String> names) async {
    final file = await _fileNamesFile;
    final temp = File('${file.path}.tmp');
    try {
      await temp.writeAsString(jsonEncode(names), flush: true);
      await file.writeAsBytes(await temp.readAsBytes(), flush: true);
      if (await temp.exists()) await temp.delete();
    } on FileSystemException {
      if (await temp.exists()) await temp.delete();
      throw const ExpenseStorageException('无法保存自定义文件名');
    }
  }

  Future<Map<String, List<LedgerFile>>> _loadLedgerFiles() async {
    final file = await _ledgerFilesFile;
    if (!await file.exists()) return {};
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map<String, dynamic>) return {};
      final result = <String, List<LedgerFile>>{};
      for (final entry in decoded.entries) {
        if (entry.value is! List) continue;
        final files = (entry.value as List)
            .map(LedgerFile.tryFromJson)
            .whereType<LedgerFile>()
            .where((item) => item.id != LedgerFile.defaultId)
            .where((item) {
              try {
                return normalizeTxtFileName(item.fileName) == item.fileName;
              } on ExpenseStorageException {
                return false;
              }
            })
            .toList();
        if (files.isNotEmpty) result[entry.key] = files;
      }
      return result;
    } on FormatException {
      return {};
    } on FileSystemException {
      throw const ExpenseStorageException('无法读取 TXT 文件列表');
    }
  }

  Future<void> _saveLedgerFiles(
    Map<String, List<LedgerFile>> configured,
  ) async {
    final file = await _ledgerFilesFile;
    final temp = File('${file.path}.tmp');
    try {
      final data = configured.map(
        (key, value) => MapEntry(
          key,
          value.map((item) => item.toJson()).toList(growable: false),
        ),
      );
      await temp.writeAsString(jsonEncode(data), flush: true);
      await file.writeAsBytes(await temp.readAsBytes(), flush: true);
      if (await temp.exists()) await temp.delete();
    } on FileSystemException {
      if (await temp.exists()) await temp.delete();
      throw const ExpenseStorageException('无法保存 TXT 文件列表');
    }
  }

  Future<Map<String, LedgerLineFormat>> _loadLineFormats() async {
    final file = await _lineFormatsFile;
    if (!await file.exists()) return {};
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map<String, dynamic>) return {};
      return decoded.map(
        (key, value) => MapEntry(key, LedgerLineFormat.parse(value)),
      );
    } on FormatException {
      return {};
    } on FileSystemException {
      throw const ExpenseStorageException('无法读取 TXT 格式设置');
    }
  }

  Future<void> _saveLineFormats(Map<String, LedgerLineFormat> formats) async {
    final file = await _lineFormatsFile;
    final temp = File('${file.path}.tmp');
    try {
      final data = formats.map((key, value) => MapEntry(key, value.name));
      await temp.writeAsString(jsonEncode(data), flush: true);
      await file.writeAsBytes(await temp.readAsBytes(), flush: true);
      if (await temp.exists()) await temp.delete();
    } on FileSystemException {
      if (await temp.exists()) await temp.delete();
      throw const ExpenseStorageException('无法保存 TXT 格式设置');
    }
  }

  Future<Set<DateTime>> _configuredMonths() async {
    final configured = await _loadLedgerFiles();
    return configured.keys.map(_parseMonthKey).whereType<DateTime>().toSet();
  }
}

String _monthKey(DateTime month) =>
    '${month.year.toString().padLeft(4, '0')}-${month.month.toString().padLeft(2, '0')}';

String _lineFormatKey(DateTime month, String fileId) =>
    '${_monthKey(month)}|$fileId';

DateTime? _parseMonthKey(String value) {
  final match = RegExp(r'^(\d{4})-(\d{2})$').firstMatch(value);
  if (match == null) return null;
  final year = int.tryParse(match.group(1)!);
  final month = int.tryParse(match.group(2)!);
  if (year == null ||
      month == null ||
      year < 2000 ||
      year > 2100 ||
      month < 1 ||
      month > 12) {
    return null;
  }
  return DateTime(year, month);
}

String defaultMonthFileName(DateTime month) =>
    '${month.year}年${month.month}月消费.txt';

/// 将用户输入规范化为安全的纯文件名，并固定 TXT 扩展名。
String normalizeTxtFileName(String input) {
  var name = input.trim();
  if (name.toLowerCase().endsWith('.txt')) {
    name = name.substring(0, name.length - 4).trim();
  }
  if (name.isEmpty) throw const ExpenseStorageException('文件名不能为空');
  if (name.length > 60) throw const ExpenseStorageException('文件名不能超过60个字符');
  if (name == '.' ||
      name == '..' ||
      name.endsWith('.') ||
      name.contains(RegExp(r'[\x00-\x1f<>:"/\\|?*]'))) {
    throw const ExpenseStorageException('文件名包含不允许的字符');
  }
  final reserved = RegExp(
    r'^(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])(?:\..*)?$',
    caseSensitive: false,
  );
  if (reserved.hasMatch(name)) {
    throw const ExpenseStorageException('不能使用系统保留文件名');
  }
  return '$name.txt';
}

String formatAmount(double amount) => amount == amount.roundToDouble()
    ? amount.toStringAsFixed(0)
    : amount.toStringAsFixed(2).replaceFirst(RegExp(r'0$'), '');

/// TXT 中支出不加符号，只有收入金额使用“+”前缀。
String formatTxtAmount(TransactionType type, double amount) =>
    '${type == TransactionType.income ? '+' : ''}${formatAmount(amount)}';

/// 生成月度 TXT：每天一行，同一天的多笔记录使用英文逗号分隔。
String buildMonthTxt(
  List<ExpenseRecord> records,
  DateTime month, {
  String fileId = LedgerFile.defaultId,
  LedgerLineFormat lineFormat = LedgerLineFormat.day,
}) {
  final grouped = <int, List<ExpenseRecord>>{};
  for (final item in records) {
    if (item.date.year == month.year &&
        item.date.month == month.month &&
        item.ledgerFileId == fileId) {
      // 保留用户的记账顺序，只对日期行进行升序排列。
      grouped.putIfAbsent(item.date.day, () => []).add(item);
    }
  }
  final days = grouped.keys.toList()..sort();
  return days
      .map((day) {
        final values = grouped[day]!.map(
          (item) =>
              '${_safeTxtText(item.reason)}:${formatTxtAmount(item.type, item.amount)}',
        );
        final prefix = lineFormat == LedgerLineFormat.fullDate
            ? '${month.year}年${month.month}月$day日'
            : '$day日';
        return '$prefix:${values.join(',')}';
      })
      .join('\n');
}

// 防止换行和分隔符把一条消费伪装成多条 TXT 记录。
String _safeTxtText(String value) => value
    .replaceAll(RegExp(r'[\r\n]+'), ' ')
    .replaceAll(':', '：')
    .replaceAll(',', '，')
    .trim();
