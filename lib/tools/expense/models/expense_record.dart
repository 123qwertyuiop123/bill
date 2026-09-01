import 'transaction_category.dart';
import 'transaction_type.dart';

class ExpenseRecord {
  const ExpenseRecord({
    required this.id,
    required this.reason,
    required this.amount,
    required this.date,
    required this.type,
    required this.category,
    this.ledgerFileId = 'default',
  });

  final String id;
  final String reason;
  final double amount;
  final DateTime date;
  final TransactionType type;
  final TransactionCategory category;
  final String ledgerFileId;

  ExpenseRecord copyWith({
    String? reason,
    double? amount,
    DateTime? date,
    TransactionType? type,
    TransactionCategory? category,
    String? ledgerFileId,
  }) => ExpenseRecord(
    id: id,
    reason: reason ?? this.reason,
    amount: amount ?? this.amount,
    date: date ?? this.date,
    type: type ?? this.type,
    category: category ?? this.category,
    ledgerFileId: ledgerFileId ?? this.ledgerFileId,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'reason': reason,
    'amount': amount,
    'date': date.toIso8601String(),
    'type': type.name,
    'category': category.name,
    'ledgerFileId': ledgerFileId,
  };

  /// 从磁盘读取的数据属于不可信输入，因此逐字段检查类型和值域。
  static ExpenseRecord? tryFromJson(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    final id = value['id'];
    final reason = value['reason'];
    final amountValue = value['amount'];
    final dateValue = value['date'];
    final ledgerFileIdValue = value['ledgerFileId'];
    if (id is! String ||
        id.isEmpty ||
        id.length > 64 ||
        reason is! String ||
        reason.trim().isEmpty ||
        reason.length > 40 ||
        amountValue is! num ||
        dateValue is! String) {
      return null;
    }
    final ledgerFileId = ledgerFileIdValue is String
        ? ledgerFileIdValue
        : 'default';
    if (ledgerFileId.isEmpty || ledgerFileId.length > 64) return null;
    final amount = amountValue.toDouble();
    final date = DateTime.tryParse(dateValue);
    if (!amount.isFinite ||
        amount <= 0 ||
        amount > 100000000 ||
        date == null ||
        date.year < 2000 ||
        date.year > 2100) {
      return null;
    }
    final typeValue = value['type'];
    final categoryValue = value['category'];
    final type = TransactionType.parse(typeValue is String ? typeValue : null);
    return ExpenseRecord(
      id: id,
      reason: reason.trim(),
      amount: amount,
      date: DateTime(date.year, date.month, date.day),
      type: type,
      category: TransactionCategory.parse(
        categoryValue is String ? categoryValue : null,
        type,
      ),
      ledgerFileId: ledgerFileId,
    );
  }
}
