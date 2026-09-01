import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/widgets/tool_widgets.dart';
import '../../core/app_theme.dart';

class PasswordGeneratorScreen extends StatefulWidget {
  const PasswordGeneratorScreen({super.key});

  @override
  State<PasswordGeneratorScreen> createState() =>
      _PasswordGeneratorScreenState();
}

class _PasswordGeneratorScreenState extends State<PasswordGeneratorScreen> {
  double length = 16;
  bool upper = true;
  bool lower = true;
  bool numbers = true;
  bool symbols = true;
  String password = '';

  @override
  void initState() {
    super.initState();
    _generate();
  }

  void _generate() {
    const upperChars = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
    const lowerChars = 'abcdefghijkmnopqrstuvwxyz';
    const numberChars = '23456789';
    const symbolChars = r'!@#$%&*+-_?';
    final groups = <String>[
      if (upper) upperChars,
      if (lower) lowerChars,
      if (numbers) numberChars,
      if (symbols) symbolChars,
    ];
    if (groups.isEmpty) return;
    final secure = Random.secure();
    final chars = <String>[
      for (final group in groups) group[secure.nextInt(group.length)],
    ];
    final all = groups.join();
    while (chars.length < length.round()) {
      chars.add(all[secure.nextInt(all.length)]);
    }
    chars.shuffle(secure);
    setState(() => password = chars.join());
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: password));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('密码已复制')));
  }

  @override
  Widget build(BuildContext context) => ToolPageScaffold(
    title: '密码生成',
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          elevation: 0,
          color: AppColors.selected,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                SelectableText(
                  password,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton.icon(
                      onPressed: _copy,
                      icon: const Icon(Icons.copy_outlined),
                      label: const Text('复制'),
                    ),
                    TextButton.icon(
                      onPressed: _generate,
                      icon: const Icon(Icons.refresh),
                      label: const Text('重新生成'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text('长度：${length.round()}'),
        Slider(
          value: length,
          min: 8,
          max: 32,
          divisions: 24,
          label: length.round().toString(),
          onChanged: (value) => setState(() => length = value),
          onChangeEnd: (_) => _generate(),
        ),
        _option('大写字母', upper, (value) => upper = value),
        _option('小写字母', lower, (value) => lower = value),
        _option('数字', numbers, (value) => numbers = value),
        _option('符号', symbols, (value) => symbols = value),
        const SizedBox(height: 12),
        const Text(
          '密码只在当前页面生成，不保存、不上传。',
          style: TextStyle(color: AppColors.muted),
        ),
      ],
    ),
  );

  Widget _option(String title, bool value, ValueChanged<bool> assign) =>
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(title),
        value: value,
        onChanged: (next) {
          if (!next &&
              [upper, lower, numbers, symbols].where((item) => item).length ==
                  1) {
            return;
          }
          setState(() => assign(next));
          _generate();
        },
      );
}
