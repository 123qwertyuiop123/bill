import 'package:flutter/material.dart';

/// 工具所属分类。分类值固定，避免持久化时依赖会变化的中文文案。
enum ToolCategory { life, calculation, text, security, productivity }

extension ToolCategoryLabel on ToolCategory {
  String get label => switch (this) {
    ToolCategory.life => '生活',
    ToolCategory.calculation => '计算',
    ToolCategory.text => '文本',
    ToolCategory.security => '安全',
    ToolCategory.productivity => '效率',
  };
}

/// 工具箱中一个工具的只读描述。
///
/// 页面构建器只保存在内存中；本地偏好仅保存 [id]，不会序列化路由或用户内容。
class ToolDefinition {
  const ToolDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.icon,
    required this.builder,
  });

  final String id;
  final String title;
  final String description;
  final ToolCategory category;
  final IconData icon;
  final WidgetBuilder builder;
}
