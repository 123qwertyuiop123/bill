import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/widgets/tool_result_widgets.dart';
import '../../app/widgets/tool_widgets.dart';
import '../../core/app_theme.dart';
import 'aspect_ratio_calculator_logic.dart';

class AspectRatioCalculatorScreen extends StatefulWidget {
  const AspectRatioCalculatorScreen({super.key});

  @override
  State<AspectRatioCalculatorScreen> createState() =>
      _AspectRatioCalculatorScreenState();
}

class _AspectRatioCalculatorScreenState
    extends State<AspectRatioCalculatorScreen> {
  final _width = TextEditingController(text: '1920');
  final _height = TextEditingController(text: '1080');
  final _targetWidth = TextEditingController(text: '1280');
  final _targetHeight = TextEditingController(text: '720');
  AspectRatioResult? _result;
  String? _error;
  bool _updatingTarget = false;

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _calculate() {
    setState(() {
      _error = null;
      try {
        _result = calculateAspectRatio(_width.text, _height.text);
        _syncHeight();
      } on FormatException catch (error) {
        _result = null;
        _error = error.message;
      }
    });
  }

  void _syncHeight() {
    if (_updatingTarget || _result == null) return;
    final width = int.tryParse(_targetWidth.text.trim());
    if (width == null) return;
    try {
      _updatingTarget = true;
      _targetHeight.text = _result!.heightForWidth(width).toString();
    } on RangeError {
      _targetHeight.clear();
    } finally {
      _updatingTarget = false;
    }
  }

  void _syncWidth() {
    if (_updatingTarget || _result == null) return;
    final height = int.tryParse(_targetHeight.text.trim());
    if (height == null) return;
    try {
      _updatingTarget = true;
      _targetWidth.text = _result!.widthForHeight(height).toString();
    } on RangeError {
      _targetWidth.clear();
    } finally {
      _updatingTarget = false;
    }
  }

  void _applyPreset(int width, int height) {
    _width.text = width.toString();
    _height.text = height.toString();
    _calculate();
  }

  @override
  void dispose() {
    _width.dispose();
    _height.dispose();
    _targetWidth.dispose();
    _targetHeight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ToolPageScaffold(
    title: '宽高比计算',
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('计算比例并等比换算尺寸'),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _dimensionField(_width, '原始宽度')),
            const SizedBox(width: 12),
            Expanded(child: _dimensionField(_height, '原始高度')),
          ],
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              _error!,
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
        FilledButton(
          key: const Key('calculateAspectRatio'),
          onPressed: _calculate,
          child: const Text('计算比例'),
        ),
        const SizedBox(height: 16),
        if (_result case final result?) ...[
          ToolResultCard(
            values: {
              '最简比例': result.ratioLabel,
              '小数比例': result.decimal.toStringAsFixed(4),
              '方向': result.orientation,
            },
          ),
          const SizedBox(height: 20),
          const Text('等比换算', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _dimensionField(
                  _targetWidth,
                  '目标宽度',
                  onChanged: (_) => setState(_syncHeight),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.lock_outline),
              ),
              Expanded(
                child: _dimensionField(
                  _targetHeight,
                  '目标高度',
                  onChanged: (_) => setState(_syncWidth),
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _preset('16:9', 16, 9),
              _preset('4:3', 4, 3),
              _preset('1:1', 1, 1),
              _preset('3:2', 3, 2),
              _preset('9:16', 9, 16),
            ],
          ),
          const SizedBox(height: 12),
          CopyResultButton(
            text:
                '${result.ratioLabel} · ${_targetWidth.text} × ${_targetHeight.text}',
          ),
        ] else
          const Text('输入宽度和高度后点击“计算比例”'),
        const SizedBox(height: 12),
        const Text('只做数值计算，不读取图片', style: TextStyle(color: AppColors.muted)),
      ],
    ),
  );

  Widget _dimensionField(
    TextEditingController controller,
    String label, {
    ValueChanged<String>? onChanged,
  }) => TextField(
    controller: controller,
    keyboardType: TextInputType.number,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    maxLength: 6,
    // 1000000 等输入需要明确报错，不能静默截断为允许的 100000。
    maxLengthEnforcement: MaxLengthEnforcement.none,
    decoration: InputDecoration(labelText: label, counterText: ''),
    onChanged: onChanged,
  );

  Widget _preset(String label, int width, int height) => ChoiceChip(
    label: Text(label),
    selected: _result?.ratioWidth == width && _result?.ratioHeight == height,
    onSelected: (_) => _applyPreset(width, height),
  );
}
