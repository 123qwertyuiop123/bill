import 'package:flutter/material.dart';

import '../../app/widgets/tool_widgets.dart';
import '../../core/app_theme.dart';

/// 基础四则计算器。使用状态机完成运算，不执行用户输入的代码或表达式。
class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String display = '0';
  double? left;
  String? operation;
  bool replaceDisplay = false;

  void _press(String key) {
    setState(() {
      if (key == 'C') {
        display = '0';
        left = null;
        operation = null;
        replaceDisplay = false;
      } else if (key == '⌫') {
        if (replaceDisplay || display.length <= 1) {
          display = '0';
        } else {
          display = display.substring(0, display.length - 1);
        }
        replaceDisplay = false;
      } else if ('+-×÷'.contains(key)) {
        left = double.tryParse(display);
        operation = key;
        replaceDisplay = true;
      } else if (key == '=') {
        _calculate();
      } else if (key == '.') {
        if (replaceDisplay) {
          display = '0.';
          replaceDisplay = false;
        } else if (!display.contains('.')) {
          display += '.';
        }
      } else {
        display = replaceDisplay || display == '0' ? key : '$display$key';
        replaceDisplay = false;
      }
    });
  }

  void _calculate() {
    final a = left;
    final b = double.tryParse(display);
    if (a == null || b == null || operation == null) return;
    final result = switch (operation) {
      '+' => a + b,
      '-' => a - b,
      '×' => a * b,
      '÷' when b != 0 => a / b,
      _ => double.nan,
    };
    display = result.isFinite ? _format(result) : '错误';
    left = null;
    operation = null;
    replaceDisplay = true;
  }

  String _format(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(8).replaceFirst(RegExp(r'0+$'), '');

  @override
  Widget build(BuildContext context) {
    const keys = [
      'C',
      '⌫',
      '÷',
      '×',
      '7',
      '8',
      '9',
      '-',
      '4',
      '5',
      '6',
      '+',
      '1',
      '2',
      '3',
      '=',
      '0',
      '.',
    ];
    return ToolPageScaffold(
      title: '计算器',
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              SizedBox(
                height: 110,
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      display,
                      style: const TextStyle(
                        fontSize: 52,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.15,
                ),
                itemCount: keys.length,
                itemBuilder: (context, index) {
                  final key = keys[index];
                  final isAction = '+-×÷='.contains(key);
                  return FilledButton(
                    onPressed: () => _press(key),
                    style: FilledButton.styleFrom(
                      padding: EdgeInsets.zero,
                      backgroundColor: isAction
                          ? AppColors.primary
                          : Colors.white,
                      foregroundColor: isAction ? Colors.white : AppColors.ink,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: isAction
                            ? BorderSide.none
                            : const BorderSide(color: AppColors.line),
                      ),
                    ),
                    child: Text(key, style: const TextStyle(fontSize: 22)),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
