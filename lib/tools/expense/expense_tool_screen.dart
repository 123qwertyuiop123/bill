import 'package:flutter/material.dart';

import 'screens/home_shell.dart';

/// 账本工具入口。
///
/// 账本的页面、业务、模型和存储均封装在当前工具目录中。
class ExpenseToolScreen extends StatelessWidget {
  const ExpenseToolScreen({super.key});

  @override
  Widget build(BuildContext context) => const HomeShell(showBackButton: true);
}
