import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../models/tool_definition.dart';

/// 工具页面统一标题栏，保证返回、收藏等操作位置一致。
class ToolPageScaffold extends StatelessWidget {
  const ToolPageScaffold({
    required this.title,
    required this.child,
    super.key,
    this.actions,
  });

  final String title;
  final Widget child;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      actions: actions,
    ),
    body: SafeArea(child: child),
  );
}

class ToolIcon extends StatelessWidget {
  const ToolIcon(this.icon, {super.key, this.size = 46});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: AppColors.selected,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Icon(icon, color: AppColors.primary, size: size * .52),
  );
}

class ToolListTile extends StatelessWidget {
  const ToolListTile({
    required this.tool,
    required this.onTap,
    super.key,
    this.trailing,
  });

  final ToolDefinition tool;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
    leading: ToolIcon(tool.icon),
    title: Text(
      tool.title,
      style: const TextStyle(fontWeight: FontWeight.w700),
    ),
    subtitle: Text(
      tool.description,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
    trailing: trailing ?? const Icon(Icons.chevron_right),
    onTap: onTap,
  );
}
