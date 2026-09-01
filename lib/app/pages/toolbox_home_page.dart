import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../controllers/toolbox_controller.dart';
import '../models/tool_definition.dart';
import '../widgets/tool_widgets.dart';

class ToolboxHomePage extends StatefulWidget {
  const ToolboxHomePage({
    required this.controller,
    required this.openTool,
    super.key,
  });

  final ToolboxController controller;
  final ValueChanged<ToolDefinition> openTool;

  @override
  State<ToolboxHomePage> createState() => _ToolboxHomePageState();
}

class _ToolboxHomePageState extends State<ToolboxHomePage> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final results = widget.controller.tools
        .where(
          (tool) =>
              query.isEmpty ||
              '${tool.title}${tool.description}'.toLowerCase().contains(
                query.toLowerCase(),
              ),
        )
        .toList();
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        children: [
          const Text(
            'ZM 工具箱',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text('简单、离线、随手可用', style: TextStyle(color: AppColors.muted)),
          const SizedBox(height: 18),
          TextField(
            onChanged: (value) => setState(() => query = value.trim()),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: '搜索工具',
            ),
          ),
          const SizedBox(height: 24),
          Text(
            query.isEmpty ? '常用工具' : '搜索结果',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          if (results.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: Text('没有找到相关工具')),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 12,
                crossAxisSpacing: 8,
                childAspectRatio: .78,
              ),
              itemCount: results.length,
              itemBuilder: (context, index) {
                final tool = results[index];
                return InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => widget.openTool(tool),
                  onLongPress: () => widget.controller.toggleFavorite(tool.id),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ToolIcon(tool.icon, size: 50),
                      const SizedBox(height: 8),
                      Text(
                        tool.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          const SizedBox(height: 24),
          if (widget.controller.recents.isNotEmpty) ...[
            const Text(
              '最近使用',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            for (final tool in widget.controller.recents.take(4))
              ToolListTile(tool: tool, onTap: () => widget.openTool(tool)),
          ],
        ],
      ),
    );
  }
}
