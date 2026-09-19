import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/widgets/tool_result_widgets.dart';
import '../../app/widgets/tool_widgets.dart';
import '../../core/app_theme.dart';
import 'resistor_decoder_logic.dart';

/// 电阻标识的离线解码页面，输入只在当前页面保留。
class ResistorDecoderScreen extends StatefulWidget {
  const ResistorDecoderScreen({super.key});
  @override
  State<ResistorDecoderScreen> createState() => _ResistorDecoderScreenState();
}

class _ResistorDecoderScreenState extends State<ResistorDecoderScreen> {
  final _smd = TextEditingController();
  bool _smdMode = false;
  int _bandCount = 4;
  List<ResistorColor> _bands = [
    ResistorColor.brown,
    ResistorColor.black,
    ResistorColor.red,
    ResistorColor.gold,
  ];
  ResistorResult? _result;
  String? _error;

  @override
  void dispose() {
    _smd.dispose();
    super.dispose();
  }

  void _invalidate() {
    _result = null;
    _error = null;
  }

  void _decode() => setState(() {
    _invalidate();
    try {
      _result = _smdMode
          ? decodeSmdResistor(_smd.text)
          : decodeResistorBands(_bands);
    } on FormatException catch (error) {
      _error = error.message;
    }
  });

  Map<String, String> _values(ResistorResult result) => {
    '标称阻值': formatResistance(result.ohms),
    '误差': result.tolerancePercent == null
        ? '数字编码无法确定'
        : '±${result.tolerancePercent}%',
    if (result.minimum != null)
      '范围':
          '${formatResistance(result.minimum!)} – ${formatResistance(result.maximum!)}',
  };

  List<ResistorColor> _choices(int index) {
    if (index == _bandCount - 1) {
      return ResistorColor.values
          .where((color) => color.tolerance != null)
          .toList();
    }
    if (index == _bandCount - 2) return ResistorColor.values;
    return ResistorColor.values
        .where((color) => color.exponent >= (index == 0 ? 1 : 0))
        .toList();
  }

  @override
  Widget build(BuildContext context) => ToolPageScaffold(
    title: '电阻解码',
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('色环解码')),
            ButtonSegment(value: true, label: Text('贴片编码')),
          ],
          selected: {_smdMode},
          showSelectedIcon: false,
          onSelectionChanged: (selection) => setState(() {
            _smdMode = selection.first;
            _invalidate();
          }),
        ),
        const SizedBox(height: 16),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_smdMode)
                  TextField(
                    key: const Key('smdInput'),
                    controller: _smd,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    // 长编码必须完整报错，不能截断为一个看似合法的电阻。
                    maxLengthEnforcement: MaxLengthEnforcement.none,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: const InputDecoration(
                      labelText: '贴片数字编码',
                      helperText: '例如 102 或 1001；不支持 EIA-96',
                    ),
                    onChanged: (_) => setState(_invalidate),
                  )
                else ...[
                  DropdownButtonFormField<int>(
                    initialValue: _bandCount,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: '色环数量'),
                    items: const [
                      DropdownMenuItem(value: 4, child: Text('4 环')),
                      DropdownMenuItem(value: 5, child: Text('5 环')),
                    ],
                    onChanged: (value) => setState(() {
                      if (value == null || value == _bandCount) return;
                      // 保留已有有效数字、倍率和误差；第五环只增加一个有效数字。
                      final old = _bands;
                      _bands = value == 5
                          ? [
                              old[0],
                              old[1],
                              ResistorColor.black,
                              old[2],
                              old[3],
                            ]
                          : [old[0], old[1], old[3], old[4]];
                      _bandCount = value;
                      _invalidate();
                    }),
                  ),
                  for (var index = 0; index < _bandCount; index++) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<ResistorColor>(
                      key: ValueKey('band-$_bandCount-$index'),
                      initialValue: _bands[index],
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: index == _bandCount - 1
                            ? '误差'
                            : index == _bandCount - 2
                            ? '倍率'
                            : '第 ${index + 1} 环',
                      ),
                      items: [
                        for (final color in _choices(index))
                          DropdownMenuItem(
                            value: color,
                            child: Row(
                              children: [
                                Container(
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: Color(color.argb),
                                    border: Border.all(color: AppColors.line),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Flexible(child: Text(color.label)),
                              ],
                            ),
                          ),
                      ],
                      onChanged: (value) => setState(() {
                        if (value != null) _bands[index] = value;
                        _invalidate();
                      }),
                    ),
                  ],
                ],
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: const TextStyle(color: AppColors.danger),
                  ),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  key: const Key('decodeResistor'),
                  onPressed: _decode,
                  child: const Text('开始解码'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_result case final result?) ...[
          ToolResultCard(values: _values(result)),
          const SizedBox(height: 12),
          CopyResultButton(
            text: _values(result).entries
                .map((e) => '${e.key}: ${e.value}')
                .join('\n'),
          ),
        ] else
          const Text('选择色环或输入贴片编码后点击“开始解码”'),
        const SizedBox(height: 16),
        const Text('按标识解码，不替代实测；所有输入均不会保存'),
      ],
    ),
  );
}
