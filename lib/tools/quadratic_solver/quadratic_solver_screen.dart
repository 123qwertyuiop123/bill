import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/widgets/tool_result_widgets.dart';
import '../../app/widgets/tool_widgets.dart';
import '../../core/app_theme.dart';
import 'quadratic_solver_logic.dart';

/// 三个系数的独立页面，离开后不持久化输入或根。
class QuadraticSolverScreen extends StatefulWidget {
  const QuadraticSolverScreen({super.key});
  @override
  State<QuadraticSolverScreen> createState() => _QuadraticSolverScreenState();
}

class _QuadraticSolverScreenState extends State<QuadraticSolverScreen> {
  final _inputs = [
    TextEditingController(text: '1'),
    TextEditingController(text: '-3'),
    TextEditingController(text: '2'),
  ];
  EquationResult? _result;
  String? _error;
  @override
  void dispose() {
    for (final input in _inputs) {
      input.dispose();
    }
    super.dispose();
  }

  void _solve() => setState(() {
    _result = null;
    _error = null;
    try {
      _result = solveQuadratic(
        _inputs[0].text,
        _inputs[1].text,
        _inputs[2].text,
      );
    } on FormatException catch (error) {
      _error = error.message;
    }
  });

  @override
  Widget build(BuildContext context) => ToolPageScaffold(
    title: '二次方程',
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'ax² + bx + c = 0',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < 3; i++) ...[
                  TextField(
                    key: ValueKey('coefficient-$i'),
                    controller: _inputs[i],
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    maxLength: maxEquationInputLength,
                    maxLengthEnforcement: MaxLengthEnforcement.none,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: InputDecoration(
                      labelText: '系数 ${['a', 'b', 'c'][i]}',
                    ),
                    onChanged: (_) => setState(() {
                      _result = null;
                      _error = null;
                    }),
                  ),
                  const SizedBox(height: 12),
                ],
                if (_error != null)
                  Text(
                    _error!,
                    style: const TextStyle(color: AppColors.danger),
                  ),
                FilledButton(
                  key: const Key('solveQuadratic'),
                  onPressed: _solve,
                  child: const Text('求解方程'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_result case final result?) ...[
          ToolResultCard(values: {'结果类型': result.kind, ...result.values}),
          const SizedBox(height: 12),
          CopyResultButton(
            text: [
              result.kind,
              ...result.values.entries.map((e) => '${e.key}: ${e.value}'),
            ].join('\n'),
          ),
        ] else
          const Text('输入三个系数后点击“求解方程”'),
        const SizedBox(height: 16),
        const Text('仅支持固定形式，不执行表达式；结果为浮点数近似，不保存输入'),
      ],
    ),
  );
}
