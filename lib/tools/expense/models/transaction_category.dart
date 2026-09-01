import 'transaction_type.dart';

/// 收支分类使用纯文字，不保存或加载任何图片资源。
enum TransactionCategory {
  food('餐饮', TransactionType.expense),
  transport('交通', TransactionType.expense),
  shopping('购物', TransactionType.expense),
  housing('居住', TransactionType.expense),
  health('医疗', TransactionType.expense),
  expenseOther('其他', TransactionType.expense),
  salary('工资', TransactionType.income),
  bonus('奖金', TransactionType.income),
  partTime('兼职', TransactionType.income),
  investment('理财', TransactionType.income),
  gift('红包', TransactionType.income),
  incomeOther('其他', TransactionType.income);

  const TransactionCategory(this.label, this.type);
  final String label;
  final TransactionType type;

  static List<TransactionCategory> forType(TransactionType type) =>
      values.where((item) => item.type == type).toList(growable: false);

  static TransactionCategory parse(String? value, TransactionType type) {
    // 旧版 other 分类迁移到新的支出“其他”。
    if (value == 'other' && type == TransactionType.expense) {
      return TransactionCategory.expenseOther;
    }
    return values.firstWhere(
      (item) => item.name == value && item.type == type,
      orElse: () => type == TransactionType.income
          ? TransactionCategory.incomeOther
          : TransactionCategory.expenseOther,
    );
  }
}
