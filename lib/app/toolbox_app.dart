import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import 'toolbox_shell.dart';

class ToolboxApp extends StatelessWidget {
  const ToolboxApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'ZM 工具箱',
    theme: buildAppTheme(),
    home: const ToolboxShell(),
  );
}
