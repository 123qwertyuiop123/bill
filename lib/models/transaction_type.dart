/// 一笔账目的方向。持久化时使用稳定的英文 name，界面只显示中文 label。
enum TransactionType {
  expense('支出'),
  income('收入');

  const TransactionType(this.label);
  final String label;

  static TransactionType parse(String? value) => values.firstWhere(
    (item) => item.name == value,
    // 兼容旧版本：历史数据没有 type 字段，全部属于支出。
    orElse: () => TransactionType.expense,
  );
}
