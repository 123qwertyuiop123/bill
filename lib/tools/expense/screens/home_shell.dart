import 'package:flutter/material.dart';

import '../controllers/expense_controller.dart';
import '../../../core/app_theme.dart';
import '../models/expense_record.dart';
import '../widgets/expense_form_sheet.dart';
import 'ledger_screen.dart';
import 'stats_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, this.showBackButton = false});

  /// 作为工具箱子页面打开时显示返回栏；旧的独立入口仍可关闭它。
  final bool showBackButton;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late final ExpenseController controller;
  int page = 0;

  @override
  void initState() {
    super.initState();
    controller = ExpenseController()..initialize();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _addExpense() async {
    final record = await showModalBottomSheet<ExpenseRecord>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ExpenseFormSheet(),
    );
    if (record == null || !mounted) return;
    final success = await controller.add(record);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            success
                ? controller.publicSyncError ?? '收支已保存，公共 TXT 已自动更新'
                : controller.error ?? '保存失败',
          ),
        ),
      );
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
      if (controller.error != null && controller.records.isEmpty) {
        return Scaffold(
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 46,
                      color: AppColors.danger,
                    ),
                    const SizedBox(height: 12),
                    Text(controller.error!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: controller.initialize,
                      child: const Text('重试'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
      return Scaffold(
        appBar: widget.showBackButton
            ? AppBar(title: const Text('收支账本'))
            : null,
        body: SafeArea(
          child: IgnorePointer(
            ignoring: controller.saving,
            child: IndexedStack(
              index: page,
              children: [
                LedgerScreen(controller: controller),
                StatsScreen(controller: controller),
              ],
            ),
          ),
        ),
        floatingActionButton: page == 0
            ? FloatingActionButton.extended(
                onPressed: controller.saving ? null : _addExpense,
                elevation: 0,
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.primary),
                ),
                icon: const Icon(Icons.add_circle_outline),
                label: const Text(
                  '记一笔',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              )
            : null,
        bottomNavigationBar: NavigationBar(
          selectedIndex: page,
          onDestinationSelected: controller.saving
              ? null
              : (value) => setState(() => page = value),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(
                Icons.menu_book_outlined,
                color: AppColors.primary,
              ),
              label: '账本',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(
                Icons.bar_chart_outlined,
                color: AppColors.primary,
              ),
              label: '统计',
            ),
          ],
        ),
      );
    },
  );
}
