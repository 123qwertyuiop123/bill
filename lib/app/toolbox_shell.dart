import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../tools/tool_registry.dart';
import 'controllers/toolbox_controller.dart';
import 'models/tool_definition.dart';
import 'pages/my_tools_page.dart';
import 'pages/settings_page.dart';
import 'pages/tool_categories_page.dart';
import 'pages/toolbox_home_page.dart';

class ToolboxShell extends StatefulWidget {
  const ToolboxShell({super.key});

  @override
  State<ToolboxShell> createState() => _ToolboxShellState();
}

class _ToolboxShellState extends State<ToolboxShell> {
  late final ToolboxController controller;
  int page = 0;

  @override
  void initState() {
    super.initState();
    controller = ToolboxController(tools: ToolRegistry.tools)..initialize();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _openTool(ToolDefinition tool) async {
    // 最近使用先落盘，再进入页面；页面退出或被系统回收也不会丢失记录。
    await controller.markUsed(tool.id);
    if (!mounted) return;
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: tool.builder));
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      if (controller.loading) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
        );
      }
      final pages = [
        ToolboxHomePage(controller: controller, openTool: _openTool),
        ToolCategoriesPage(controller: controller, openTool: _openTool),
        MyToolsPage(controller: controller, openTool: _openTool),
        SettingsPage(controller: controller),
      ];
      return Scaffold(
        body: IndexedStack(index: page, children: pages),
        bottomNavigationBar: NavigationBar(
          selectedIndex: page,
          onDestinationSelected: (value) => setState(() => page = value),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_outlined, color: AppColors.primary),
              label: '首页',
            ),
            NavigationDestination(
              icon: Icon(Icons.grid_view_outlined),
              selectedIcon: Icon(
                Icons.grid_view_outlined,
                color: AppColors.primary,
              ),
              label: '分类',
            ),
            NavigationDestination(
              icon: Icon(Icons.star_border),
              selectedIcon: Icon(Icons.star, color: AppColors.primary),
              label: '收藏',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(
                Icons.settings_outlined,
                color: AppColors.primary,
              ),
              label: '设置',
            ),
          ],
        ),
      );
    },
  );
}
