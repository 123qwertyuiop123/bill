import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/widgets/tool_widgets.dart';
import '../../app/widgets/tool_result_widgets.dart';
import 'chmod_calculator_logic.dart';
import 'widgets/permission_matrix.dart';

class ChmodCalculatorScreen extends StatefulWidget {
  const ChmodCalculatorScreen({super.key});
  @override
  State<ChmodCalculatorScreen> createState() => _ChmodCalculatorScreenState();
}

class _ChmodCalculatorScreenState extends State<ChmodCalculatorScreen> {
  final _input = TextEditingController(text: '755');
  UnixPermissions? _value = UnixPermissions.parse('755');
  String? _error;

  void _parse(String text) => setState(() {
    _value = null;
    _error = null;
    try {
      _value = UnixPermissions.parse(text);
    } on FormatException catch (e) {
      _error = e.message;
    }
  });

  void _toggle(int index) => setState(() {
    if (_value == null) return;
    _value = _value!.toggle(index);
    _input.text = _value!.octal;
    _error = null;
  });

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ToolPageScaffold(
    title: '权限计算',
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('计算 Unix 权限，不修改文件'),
        const SizedBox(height: 16),
        TextField(
          controller: _input,
          maxLength: 3,
          // 0755 等特殊形式必须报错，不能截断为另一个有效权限值。
          maxLengthEnforcement: MaxLengthEnforcement.none,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: '八进制权限',
            errorText: _error,
            errorMaxLines: 3,
          ),
          onChanged: _parse,
        ),
        const SizedBox(height: 16),
        PermissionMatrix(value: _value, onToggle: _toggle),
        const SizedBox(height: 16),
        if (_value case final value?)
          ToolResultCard(values: {'权限表示': value.symbolic, '八进制': value.octal})
        else
          const Text('请输入三位有效权限后继续勾选'),
        const SizedBox(height: 12),
        CopyResultButton(
          text: _value == null ? '' : '${_value!.octal}\n${_value!.symbolic}',
        ),
        const SizedBox(height: 12),
        const Text('只做权限换算，不执行命令；暂不支持特殊权限位'),
      ],
    ),
  );
}
