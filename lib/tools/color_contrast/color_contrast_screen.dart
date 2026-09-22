import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/widgets/tool_widgets.dart';
import '../../core/app_theme.dart';
import 'color_contrast_logic.dart';

enum _ColorMode { contrast, conversion, simulation, palette }

/// 颜色检查完全在内存中完成；色觉模拟只用于无障碍设计预览。
class ColorContrastScreen extends StatefulWidget {
  const ColorContrastScreen({super.key});

  @override
  State<ColorContrastScreen> createState() => _ColorContrastScreenState();
}

class _ColorContrastScreenState extends State<ColorContrastScreen> {
  final foregroundController = TextEditingController(text: '#1F2937');
  final backgroundController = TextEditingController(text: '#FFFFFF');
  final formatInputController = TextEditingController(text: '#197A4A');
  final paletteInputController = TextEditingController(text: '#197A4A');
  _ColorMode mode = _ColorMode.contrast;
  ColorInputFormat inputFormat = ColorInputFormat.hex;
  ColorVisionType visionType = ColorVisionType.deuteranopia;
  ColorContrastResult? contrastResult;
  ColorFormatConversionResult? conversionResult;
  ColorVisionSimulationResult? simulationResult;
  ColorPaletteResult? paletteResult;

  @override
  void dispose() {
    foregroundController.dispose();
    backgroundController.dispose();
    formatInputController.dispose();
    paletteInputController.dispose();
    super.dispose();
  }

  void _invalidate() => setState(() {
    contrastResult = null;
    conversionResult = null;
    simulationResult = null;
    paletteResult = null;
  });

  void _run() => setState(() {
    contrastResult = null;
    conversionResult = null;
    simulationResult = null;
    paletteResult = null;
    if (mode == _ColorMode.contrast) {
      contrastResult = checkColorContrast(
        foregroundController.text,
        backgroundController.text,
      );
    } else if (mode == _ColorMode.conversion) {
      conversionResult = convertColorFormat(
        formatInputController.text,
        inputFormat,
      );
    } else if (mode == _ColorMode.simulation) {
      simulationResult = simulateColorVision(
        foregroundController.text,
        backgroundController.text,
        visionType,
      );
    } else {
      paletteResult = generateColorPalette(paletteInputController.text);
    }
  });

  @override
  Widget build(BuildContext context) {
    final foreground =
        parseHexColor(foregroundController.text)?.color ??
        const Color(0xff1f2937);
    final background =
        parseHexColor(backgroundController.text)?.color ?? Colors.white;
    final error =
        contrastResult?.error ??
        conversionResult?.error ??
        simulationResult?.error ??
        paletteResult?.error;
    return ToolPageScaffold(
      title: '颜色与对比度',
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<_ColorMode>(
              segments: const [
                ButtonSegment(value: _ColorMode.contrast, label: Text('对比度')),
                ButtonSegment(
                  value: _ColorMode.conversion,
                  label: Text('格式转换'),
                ),
                ButtonSegment(
                  value: _ColorMode.simulation,
                  label: Text('色觉模拟'),
                ),
                ButtonSegment(value: _ColorMode.palette, label: Text('主题色阶')),
              ],
              selected: {mode},
              showSelectedIcon: false,
              onSelectionChanged: (selection) => setState(() {
                mode = selection.first;
                contrastResult = null;
                conversionResult = null;
                simulationResult = null;
                paletteResult = null;
              }),
            ),
          ),
          const SizedBox(height: 16),
          if (mode == _ColorMode.conversion)
            _ColorFormatInput(
              controller: formatInputController,
              format: inputFormat,
              previewColor:
                  conversionResult?.color?.color ??
                  convertColorFormat(
                    formatInputController.text,
                    inputFormat,
                  ).color?.color ??
                  const Color(0xff197a4a),
              onFormatChanged: (value) {
                if (value == null) return;
                setState(() {
                  inputFormat = value;
                  formatInputController.text = value.example;
                  conversionResult = null;
                });
              },
              onChanged: _invalidate,
            )
          else if (mode == _ColorMode.palette)
            _ColorInput(
              label: '种子颜色',
              fieldKey: const Key('paletteColorInput'),
              controller: paletteInputController,
              color:
                  parseHexColor(paletteInputController.text)?.color ??
                  const Color(0xff197a4a),
              onChanged: _invalidate,
            )
          else ...[
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
          ],
          const SizedBox(height: 16),
          if (mode == _ColorMode.contrast)
            _TextPreview(foreground: foreground, background: background)
          else if (mode == _ColorMode.simulation) ...[
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
          if (conversionResult?.isSuccess ?? false) ...[
            const SizedBox(height: 16),
            _ColorFormatResult(result: conversionResult!),
          ],
          if (paletteResult?.isSuccess ?? false) ...[
            const SizedBox(height: 16),
            _ColorPaletteResultCard(result: paletteResult!),
          ],
          const SizedBox(height: 16),
          FilledButton(
            key: const Key('runColorCheck'),
            onPressed: _run,
            child: Text(switch (mode) {
              _ColorMode.contrast => '检查对比度',
              _ColorMode.conversion => '转换格式',
              _ColorMode.simulation => '开始模拟',
              _ColorMode.palette => '生成色阶',
            }),
          ),
          const SizedBox(height: 8),
          Text(switch (mode) {
            _ColorMode.contrast => '结果依据 WCAG 对比度阈值，仅在本机计算。',
            _ColorMode.conversion => '颜色转换仅在本机完成，不读取图片或保存输入。',
            _ColorMode.simulation => '色觉模拟仅作无障碍设计预览，不代表医学诊断。',
            _ColorMode.palette => '色阶基于固定 HSL 明度生成；发布前仍需逐项检查实际文字对比度。',
          }, style: const TextStyle(color: AppColors.muted)),
        ],
      ),
    );
  }
}

class _ColorPaletteResultCard extends StatelessWidget {
  const _ColorPaletteResultCard({required this.result});

  final ColorPaletteResult result;

  @override
  Widget build(BuildContext context) => Card(
    key: const Key('paletteResult'),
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('主题色阶', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tone in result.tones) _PaletteSwatch(tone: tone),
            ],
          ),
          const Divider(height: 28),
          _CopyableColorRow(label: '建议前景色', value: result.suggestedForeground!),
          Text(
            '与种子色对比度 ${result.foregroundContrast!.toStringAsFixed(2)} : 1',
            style: const TextStyle(color: AppColors.muted),
          ),
        ],
      ),
    ),
  );
}

class _PaletteSwatch extends StatelessWidget {
  const _PaletteSwatch({required this.tone});

  final ColorPaletteTone tone;

  @override
  Widget build(BuildContext context) {
    final color = tone.color.color;
    final foreground =
        ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : Colors.black;
    return Semantics(
      button: true,
      label: '色阶 ${tone.tone}，${tone.hex}，点击复制',
      child: InkWell(
        onTap: () async {
          await Clipboard.setData(ClipboardData(text: tone.hex));
          if (context.mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text('已复制 ${tone.hex}')));
          }
        },
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          width: 96,
          height: 74,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              '${tone.tone}\n${tone.hex}',
              textAlign: TextAlign.center,
              style: TextStyle(color: foreground, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }
}

class _ColorFormatInput extends StatelessWidget {
  const _ColorFormatInput({
    required this.controller,
    required this.format,
    required this.previewColor,
    required this.onFormatChanged,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ColorInputFormat format;
  final Color previewColor;
  final ValueChanged<ColorInputFormat?> onFormatChanged;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          DropdownButtonFormField<ColorInputFormat>(
            key: const Key('colorInputFormat'),
            initialValue: format,
            decoration: const InputDecoration(labelText: '输入格式'),
            items: ColorInputFormat.values
                .map(
                  (item) =>
                      DropdownMenuItem(value: item, child: Text(item.label)),
                )
                .toList(),
            onChanged: onFormatChanged,
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  key: const Key('colorFormatInput'),
                  controller: controller,
                  maxLength: maxColorFormatInputLength,
                  maxLengthEnforcement: MaxLengthEnforcement.none,
                  decoration: InputDecoration(
                    labelText: '${format.label} 输入',
                    hintText: format.example,
                    counterText: '',
                  ),
                  onChanged: (_) => onChanged(),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: previewColor,
                  border: Border.all(color: AppColors.line),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _ColorFormatResult extends StatelessWidget {
  const _ColorFormatResult({required this.result});

  final ColorFormatConversionResult result;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('转换结果', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _CopyableColorRow(label: 'HEX', value: result.hex!),
          _CopyableColorRow(label: 'RGB', value: result.rgb!),
          _CopyableColorRow(label: 'HSL', value: result.hsl!),
          _CopyableColorRow(label: 'HSV', value: result.hsv!),
        ],
      ),
    ),
  );
}

class _CopyableColorRow extends StatelessWidget {
  const _CopyableColorRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    subtitle: SelectableText(value),
    trailing: IconButton(
      tooltip: '复制$label',
      onPressed: () async {
        await Clipboard.setData(ClipboardData(text: value));
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('已复制 $label')));
        }
      },
      icon: const Icon(Icons.copy_outlined),
    ),
  );
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
