import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../controllers/toolbox_controller.dart';
import '../models/tool_definition.dart';
import '../widgets/tool_widgets.dart';

class MyToolsPage extends StatefulWidget {
  const MyToolsPage({
    required this.controller,
    required this.openTool,
    super.key,
  });

  final ToolboxController controller;
  final ValueChanged<ToolDefinition> openTool;

  @override
  State<MyToolsPage> createState() => _MyToolsPageState();
}

class _MyToolsPageState extends State<MyToolsPage> {
  bool showFavorites = true;

  @override
  Widget build(BuildContext context) {
    final tools = showFavorites
        ? widget.controller.favorites
        : widget.controller.recents;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        children: [
          const Text(
            '我的工具',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('收藏')),
              ButtonSegment(value: false, label: Text('最近使用')),
            ],
            selected: {showFavorites},
            onSelectionChanged: (value) =>
                setState(() => showFavorites = value.first),
          ),
          const SizedBox(height: 18),
          if (tools.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 70),
              child: Column(
                children: [
                  Icon(
                    showFavorites ? Icons.star_border : Icons.history,
                    size: 48,
                    color: AppColors.muted,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    showFavorites ? '还没有收藏工具\n可在“分类”页点击星标收藏' : '还没有最近使用记录',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.muted),
                  ),
                ],
              ),
            )
          else
            for (final tool in tools)
              ToolListTile(
                tool: tool,
                onTap: () => widget.openTool(tool),
                trailing: showFavorites
                    ? IconButton(
                        onPressed: () =>
                            widget.controller.toggleFavorite(tool.id),
                        icon: const Icon(Icons.star),
                      )
                    : const Icon(Icons.chevron_right),
              ),
          if (!showFavorites && tools.isNotEmpty)
            TextButton(
              onPressed: widget.controller.clearRecents,
              child: const Text('清除最近使用'),
            ),
        ],
      ),
    );
  }
}
