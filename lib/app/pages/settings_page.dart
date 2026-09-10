import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../controllers/toolbox_controller.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({required this.controller, super.key});

  final ToolboxController controller;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      children: [
        const Text(
          '设置',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 18),
        _section('外观'),
        const ListTile(
          leading: Icon(Icons.brightness_auto_outlined),
          title: Text('主题'),
          subtitle: Text('跟随系统（当前使用浅色界面）'),
        ),
        _section('数据与存储'),
        const ListTile(
          leading: Icon(Icons.folder_outlined),
          title: Text('账本 TXT 位置'),
          subtitle: Text('/storage/emulated/0/Download/bill/年份/'),
        ),
        ListTile(
          leading: const Icon(Icons.history_toggle_off),
          title: const Text('清除最近使用'),
          onTap: () async {
            await controller.clearRecents();
            if (context.mounted) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('已清除最近使用')));
            }
          },
        ),
        _section('隐私'),
        const ListTile(
          leading: Icon(Icons.shield_outlined),
          title: Text('本地优先'),
          subtitle: Text('工具内容不上传；账本仍保存在本机并同步公开 TXT'),
        ),
        _section('关于'),
        const ListTile(
          leading: Icon(Icons.info_outline),
          title: Text('ZM 工具箱'),
          subtitle: Text('版本 1.0.0 · 45 个离线工具'),
        ),
      ],
    ),
  );

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.only(top: 14, bottom: 4),
    child: Text(
      title,
      style: const TextStyle(
        color: AppColors.primary,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}
