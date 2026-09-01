import 'package:flutter/material.dart';

import '../controllers/toolbox_controller.dart';
import '../models/tool_definition.dart';
import '../widgets/tool_widgets.dart';

class ToolCategoriesPage extends StatefulWidget {
  const ToolCategoriesPage({
    required this.controller,
    required this.openTool,
    super.key,
  });

  final ToolboxController controller;
  final ValueChanged<ToolDefinition> openTool;

  @override
  State<ToolCategoriesPage> createState() => _ToolCategoriesPageState();
}

class _ToolCategoriesPageState extends State<ToolCategoriesPage> {
  ToolCategory? selected;

  @override
  Widget build(BuildContext context) {
    final tools = selected == null
        ? widget.controller.tools
        : widget.controller.tools
              .where((tool) => tool.category == selected)
              .toList();
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        children: [
          const Text(
            '全部工具',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('全部'),
                  selected: selected == null,
                  onSelected: (_) => setState(() => selected = null),
                ),
                const SizedBox(width: 8),
                for (final category in ToolCategory.values) ...[
                  ChoiceChip(
                    label: Text(category.label),
                    selected: selected == category,
                    onSelected: (_) => setState(() => selected = category),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          for (final tool in tools)
            ToolListTile(
              tool: tool,
              onTap: () => widget.openTool(tool),
              trailing: IconButton(
                tooltip: widget.controller.isFavorite(tool.id) ? '取消收藏' : '收藏',
                onPressed: () => widget.controller.toggleFavorite(tool.id),
                icon: Icon(
                  widget.controller.isFavorite(tool.id)
                      ? Icons.star
                      : Icons.star_border,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
