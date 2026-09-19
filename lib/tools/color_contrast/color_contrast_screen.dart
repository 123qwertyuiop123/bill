import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/widgets/tool_widgets.dart';
import '../../core/app_theme.dart';
import 'color_contrast_logic.dart';

enum _ColorMode { contrast, simulation }

/// 颜色检查完全在内存中完成；色觉模拟只用于无障碍设计预览。
class ColorContrastScreen extends StatefulWidget {
  const ColorContrastScreen({super.key});

  @override
  State<ColorContrastScreen> createState() => _ColorContrastScreenState();
}

class _ColorContrastScreenState extends State<ColorContrastScreen> {
  final foregroundController = TextEditingController(text: '#1F2937');
  final backgroundController = TextEditingController(text: '#FFFFFF');
  _ColorMode mode = _ColorMode.contrast;
  ColorVisionType visionType = ColorVisionType.deuteranopia;
  ColorContrastResult? contrastResult;
  ColorVisionSimulationResult? simulationResult;

  @override
  void dispose() {
    foregroundController.dispose();
    backgroundController.dispose();
    super.dispose();
  }

  void _invalidate() => setState(() {
    contrastResult = null;
    simulationResult = null;
  });

  void _run() => setState(() {
    contrastResult = null;
    simulationResult = null;
    if (mode == _ColorMode.contrast) {
      contrastResult = checkColorContrast(
        foregroundController.text,
        backgroundController.text,
      );
    } else {
      simulationResult = simulateColorVision(
        foregroundController.text,
        backgroundController.text,
        visionType,
      );
    }
  });

  @override
  Widget build(BuildContext context) {
    final foreground =
        parseHexColor(foregroundController.text)?.color ??
        const Color(0xff1f2937);
    final background =
        parseHexColor(backgroundController.text)?.color ?? Colors.white;
    final error = contrastResult?.error ?? simulationResult?.error;
    return ToolPageScaffold(
      title: '颜色与对比度',
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SegmentedButton<_ColorMode>(
            segments: const [
              ButtonSegment(value: _ColorMode.contrast, label: Text('对比度')),
              ButtonSegment(value: _ColorMode.simulation, label: Text('色觉模拟')),
            ],
            selected: {mode},
            showSelectedIcon: false,
            onSelectionChanged: (selection) => setState(() {
              mode = selection.first;
              contrastResult = null;
              simulationResult = null;
            }),
          ),
          const SizedBox(height: 16),
          _ColorInput(
            label: '前景色',
            fieldKey: const Key('foregroundColorInput'),
            controller: foregroundController,
            color: foreground,
            onChanged: _invalidate,
          ),
          const SizedBox(height: 12),
          _ColorInput(
            label: '背景色',
            fieldKey: const Key('backgroundColorInput'),
            controller: backgroundController,
            color: background,
            onChanged: _invalidate,
          ),
          const SizedBox(height: 16),
          if (mode == _ColorMode.contrast)
            _TextPreview(foreground: foreground, background: background)
          else ...[
            DropdownButtonFormField<ColorVisionType>(
              key: const Key('visionType'),
              initialValue: visionType,
              isExpanded: true,
              decoration: const InputDecoration(labelText: '模拟类型'),
              items: ColorVisionType.values
                  .map(
                    (type) =>
                        DropdownMenuItem(value: type, child: Text(type.label)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  visionType = value;
                  simulationResult = null;
                });
              },
            ),
            const SizedBox(height: 16),
            _ColorPairPreview(
              title: '原始颜色',
              foreground: foreground,
              background: background,
            ),
          ],
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                error,
                style: const TextStyle(color: AppColors.danger),
              ),
            ),
          if (contrastResult?.isSuccess ?? false) ...[
            const SizedBox(height: 16),
            Text('对比度', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '${contrastResult!.ratio!.toStringAsFixed(2)} : 1',
                  key: const Key('contrastRatio'),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatusBadge(
                  label: '普通文字 AA',
                  passed: contrastResult!.normalAa,
                ),
                _StatusBadge(
                  label: '普通文字 AAA',
                  passed: contrastResult!.normalAaa,
                ),
                _StatusBadge(label: '大文字 AA', passed: contrastResult!.largeAa),
                _StatusBadge(
                  label: '大文字 AAA',
                  passed: contrastResult!.largeAaa,
                ),
              ],
            ),
          ],
          if (simulationResult?.isSuccess ?? false) ...[
            const SizedBox(height: 16),
            _ColorPairPreview(
              title: '模拟后颜色',
              foreground: simulationResult!.simulatedForeground!.color,
              background: simulationResult!.simulatedBackground!.color,
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(
            key: const Key('runColorCheck'),
            onPressed: _run,
            child: Text(mode == _ColorMode.contrast ? '检查对比度' : '开始模拟'),
          ),
          const SizedBox(height: 8),
          Text(
            mode == _ColorMode.contrast
                ? '结果依据 WCAG 对比度阈值，仅在本机计算。'
                : '色觉模拟仅作无障碍设计预览，不代表医学诊断。',
            style: const TextStyle(color: AppColors.muted),
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
    required this.onChanged,
  });

  final String label;
  final Key fieldKey;
  final TextEditingController controller;
  final Color color;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Expanded(
        child: TextField(
          key: fieldKey,
          controller: controller,
          maxLength: maxColorInputLength,
          // 保留完整粘贴内容交给逻辑层报错，避免截断后变成另一种合法颜色。
          maxLengthEnforcement: MaxLengthEnforcement.none,
          decoration: InputDecoration(labelText: label, counterText: ''),
          onChanged: (_) => onChanged(),
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

class _TextPreview extends StatelessWidget {
  const _TextPreview({required this.foreground, required this.background});
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
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
    ],
  );
}

class _ColorPairPreview extends StatelessWidget {
  const _ColorPairPreview({
    required this.title,
    required this.foreground,
    required this.background,
  });
  final String title;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(title, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: _ColorBlock(label: '前景色', color: foreground),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ColorBlock(label: '背景色', color: background),
          ),
        ],
      ),
    ],
  );
}

class _ColorBlock extends StatelessWidget {
  const _ColorBlock({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    child: Container(
      height: 72,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(10),
      ),
    ),
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
      child: Wrap(
        spacing: 8,
        children: [
          Text(label),
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
