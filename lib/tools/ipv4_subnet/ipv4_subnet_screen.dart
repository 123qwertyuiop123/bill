import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/widgets/tool_widgets.dart';
import '../../app/widgets/tool_result_widgets.dart';
import 'ipv4_subnet_logic.dart';

class Ipv4SubnetScreen extends StatefulWidget {
  const Ipv4SubnetScreen({super.key});
  @override
  State<Ipv4SubnetScreen> createState() => _Ipv4SubnetScreenState();
}

class _Ipv4SubnetScreenState extends State<Ipv4SubnetScreen> {
  final _input = TextEditingController(text: '192.168.1.10/24');
  Ipv4SubnetResult? _result;
  String? _error;

  void _calculate() {
    setState(() {
      _result = null;
      _error = null;
      try {
        _result = calculateIpv4Subnet(_input.text);
      } on FormatException catch (e) {
        // 逻辑层仅抛出预先定义的中文提示，不含原始输入。
        _error = e.message;
      }
    });
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ToolPageScaffold(
    title: 'IPv4 子网计算',
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('输入地址与前缀，查看网络范围'),
        const SizedBox(height: 16),
        TextField(
          controller: _input,
          maxLength: 64,
          maxLengthEnforcement: MaxLengthEnforcement.none,
          autocorrect: false,
          enableSuggestions: false,
          decoration: InputDecoration(
            labelText: 'IPv4 地址 / 前缀',
            errorText: _error,
            errorMaxLines: 4,
          ),
          onChanged: (_) => setState(() {
            _result = null;
            _error = null;
          }),
        ),
        const SizedBox(height: 16),
        FilledButton(onPressed: _calculate, child: const Text('计算子网')),
        const SizedBox(height: 16),
        if (_result case final result?)
          ToolResultCard(values: result.values)
        else
          const Text('输入地址后点击“计算子网”'),
        const SizedBox(height: 12),
        CopyResultButton(text: _result?.text ?? ''),
        const SizedBox(height: 12),
        const Text('仅离线计算，不扫描网络'),
      ],
    ),
  );
}
