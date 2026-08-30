import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class ExpenseRecord {
  ExpenseRecord({
    required this.id,
    required this.reason,
    required this.amount,
    required this.date,
    this.category = 'other',
  });

  final String id;
  final String reason;
  final double amount;
  final DateTime date;
  final String category;

  factory ExpenseRecord.fromJson(Map<String, dynamic> json) => ExpenseRecord(
    id: json['id'] as String,
    reason: json['reason'] as String,
    amount: (json['amount'] as num).toDouble(),
    date: DateTime.parse(json['date'] as String),
    category: json['category'] as String? ?? 'other',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'reason': reason,
    'amount': amount,
    'date': date.toIso8601String(),
    'category': category,
  };
}

class ExpenseStorage {
  Future<Directory> get _folder async {
    final documents = await getApplicationDocumentsDirectory();
    final folder = Directory('${documents.path}${Platform.pathSeparator}消费记录');
    if (!await folder.exists()) await folder.create(recursive: true);
    return folder;
  }

  Future<File> get _dataFile async {
    final folder = await _folder;
    return File('${folder.path}${Platform.pathSeparator}expenses.json');
  }

  Future<List<ExpenseRecord>> load() async {
    try {
      final file = await _dataFile;
      if (!await file.exists()) return [];
      final content = await file.readAsString();
      final values = jsonDecode(content) as List<dynamic>;
      return values
          .map((item) => ExpenseRecord.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> save(List<ExpenseRecord> records) async {
    final dataFile = await _dataFile;
    await dataFile.writeAsString(
      const JsonEncoder.withIndent('  ')
          .convert(records.map((record) => record.toJson()).toList()),
      flush: true,
    );

    final months = <String>{
      for (final record in records) '${record.date.year}-${record.date.month}',
      '${DateTime.now().year}-${DateTime.now().month}',
    };
    for (final month in months) {
      final parts = month.split('-');
      await writeMonth(
        records,
        DateTime(int.parse(parts[0]), int.parse(parts[1])),
      );
    }
  }

  Future<String> writeMonth(List<ExpenseRecord> records, DateTime month) async {
    final folder = await _folder;
    final file = File(
      '${folder.path}${Platform.pathSeparator}${month.year}年${month.month}月消费.txt',
    );
    final monthRecords =
        records
            .where(
              (record) =>
                  record.date.year == month.year &&
                  record.date.month == month.month,
            )
            .toList()
          ..sort((a, b) {
            final byDate = a.date.compareTo(b.date);
            return byDate != 0 ? byDate : a.id.compareTo(b.id);
          });

    final grouped = <int, List<ExpenseRecord>>{};
    for (final record in monthRecords) {
      grouped.putIfAbsent(record.date.day, () => []).add(record);
    }
    final text = grouped.entries
        .map(
          (entry) =>
              '${entry.key}日:${entry.value.map((record) => '${record.reason}:${formatAmount(record.amount)}').join(',')}',
        )
        .join('\n');
    await file.writeAsString(text, flush: true);
    return file.path;
  }

  Future<String> monthFilePath(DateTime month) async {
    final folder = await _folder;
    return '${folder.path}${Platform.pathSeparator}${month.year}年${month.month}月消费.txt';
  }
}

String formatAmount(double amount) => amount == amount.roundToDouble()
    ? amount.toStringAsFixed(0)
    : amount.toStringAsFixed(2).replaceFirst(RegExp(r'0$'), '');
