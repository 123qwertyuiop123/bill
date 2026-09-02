import 'package:flutter/material.dart';

import '../../app/widgets/tool_widgets.dart';
import '../../core/app_theme.dart';
import 'color_contrast_logic.dart';

class ColorContrastScreen extends StatefulWidget {
  const ColorContrastScreen({super.key});

  @override
  State<ColorContrastScreen> createState() => _ColorContrastScreenState();
}

class _ColorContrastScreenState extends State<ColorContrastScreen> {
  final foregroundController = TextEditingController(text: '#1F2937');
  final backgroundController = TextEditingController(text: '#FFFFFF');
  ColorContrastResult? result;

  @override
  void dispose() {
    foregroundController.dispose();
    backgroundController.dispose();
    super.dispose();
  }

  void _check() => setState(() {
    result = checkColorContrast(
      foregroundController.text,
      backgroundController.text,
    );
  });

  @override
  Widget build(BuildContext context) {
    final foreground = result?.foreground?.color ?? const Color(0xff1f2937);
    final background = result?.background?.color ?? Colors.white;
    return ToolPageScaffold(
      title: '颜色与对比度',
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _ColorInput(
            label: '前景色',
            fieldKey: const Key('foregroundColorInput'),
            controller: foregroundController,
            color: foreground,
          ),
          const SizedBox(height: 12),
          _ColorInput(
            label: '背景色',
            fieldKey: const Key('backgroundColorInput'),
            controller: backgroundController,
            color: background,
          ),
          const SizedBox(height: 16),
          Text('预览', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Container(
            height: 110,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: background,
              border: Border.all(color: AppColors.line),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '示例文本 Aa 123',
              style: TextStyle(
                color: foreground,
                fontSize: 25,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (result?.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                result!.error!,
                style: const TextStyle(color: AppColors.danger),
              ),
            ),
          if (result?.isSuccess ?? false) ...[
            const SizedBox(height: 16),
            Text('对比度', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '${result!.ratio!.toStringAsFixed(2)} : 1',
                  key: const Key('contrastRatio'),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
            ),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.5,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: [
                _StatusBadge(label: '普通文字 AA', passed: result!.normalAa),
                _StatusBadge(label: '普通文字 AAA', passed: result!.normalAaa),
                _StatusBadge(label: '大文字 AA', passed: result!.largeAa),
                _StatusBadge(label: '大文字 AAA', passed: result!.largeAaa),
              ],
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(onPressed: _check, child: const Text('检查对比度')),
          const SizedBox(height: 8),
          const Text(
            '结果依据 WCAG 对比度阈值，仅在本机计算。',
            style: TextStyle(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _ColorInput extends StatelessWidget {
  const _ColorInput({
    required this.label,
    required this.fieldKey,
    required this.controller,
    required this.color,
  });

  final String label;
  final Key fieldKey;
  final TextEditingController controller;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Expanded(
        child: TextField(
          key: fieldKey,
          controller: controller,
          maxLength: maxColorInputLength,
          decoration: InputDecoration(labelText: label, counterText: ''),
        ),
      ),
      const SizedBox(width: 10),
      Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    ],
  );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.passed});

  final String label;
  final bool passed;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, maxLines: 1)),
          Text(
            passed ? '通过' : '未通过',
            style: TextStyle(
              color: passed ? AppColors.primary : AppColors.danger,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );
}
