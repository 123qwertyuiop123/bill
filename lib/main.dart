import 'package:flutter/material.dart';

import 'core/app_theme.dart';
import 'screens/home_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CostBookApp());
}

class CostBookApp extends StatelessWidget {
  const CostBookApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: '收支记录',
    theme: buildAppTheme(),
    // 不在路由或日志中携带用户的消费原因和金额。
    home: const HomeShell(),
  );
}
