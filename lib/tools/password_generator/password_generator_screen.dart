import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/widgets/tool_widgets.dart';
import '../../core/app_theme.dart';
import 'password_strength_logic.dart';

enum PasswordToolSection { generate, evaluate }

class PasswordGeneratorScreen extends StatefulWidget {
  const PasswordGeneratorScreen({super.key});

  @override
  State<PasswordGeneratorScreen> createState() =>
      _PasswordGeneratorScreenState();
}

class _PasswordGeneratorScreenState extends State<PasswordGeneratorScreen> {
  final evaluationController = TextEditingController();
  double length = 16;
  bool upper = true;
  bool lower = true;
  bool numbers = true;
  bool symbols = true;
  bool obscureEvaluation = true;
  String password = '';
  PasswordToolSection section = PasswordToolSection.generate;
  PasswordStrengthResult? evaluation;

  @override
  void initState() {
    super.initState();
    password = _createPassword();
  }

  @override
  void dispose() {
    evaluationController.dispose();
    super.dispose();
  }

  String _createPassword() {
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
    final secure = Random.secure();
    final chars = <String>[
      for (final group in groups) group[secure.nextInt(group.length)],
    ];
    final all = groups.join();
    while (chars.length < length.round()) {
      chars.add(all[secure.nextInt(all.length)]);
    }
    chars.shuffle(secure);
    return chars.join();
  }

  void _generate() => setState(() => password = _createPassword());

  void _evaluate() => setState(() {
    evaluation = evaluatePasswordStrength(evaluationController.text);
  });

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
        SegmentedButton<PasswordToolSection>(
          segments: const [
            ButtonSegment(
              value: PasswordToolSection.generate,
              label: Text('生成密码'),
            ),
            ButtonSegment(
              value: PasswordToolSection.evaluate,
              label: Text('强度评估'),
            ),
          ],
          selected: {section},
          showSelectedIcon: false,
          onSelectionChanged: (selection) => setState(() {
            section = selection.first;
            evaluation = null;
          }),
        ),
        const SizedBox(height: 18),
        if (section == PasswordToolSection.generate)
          ..._buildGenerator(context)
        else
          ..._buildEvaluator(),
      ],
    ),
  );

  List<Widget> _buildGenerator(BuildContext context) => [
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
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
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
    const SizedBox(height: 16),
    _PasswordStrengthCard(result: evaluatePasswordStrength(password)),
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
    const Text('密码只在当前页面生成，不保存、不上传。', style: TextStyle(color: AppColors.muted)),
  ];

  List<Widget> _buildEvaluator() => [
    TextField(
      key: const Key('passwordEvaluationInput'),
      controller: evaluationController,
      obscureText: obscureEvaluation,
      maxLength: maxPasswordEvaluationLength,
      // 保留完整粘贴内容交给逻辑层拒绝，避免评估被静默截断后的另一个密码。
      maxLengthEnforcement: MaxLengthEnforcement.none,
      enableSuggestions: false,
      autocorrect: false,
      decoration: InputDecoration(
        labelText: '输入待检查的密码',
        helperText: '仅在点击评估后于本机内存中分析',
        suffixIcon: IconButton(
          tooltip: obscureEvaluation ? '显示密码' : '隐藏密码',
          onPressed: () => setState(() {
            obscureEvaluation = !obscureEvaluation;
          }),
          icon: Icon(
            obscureEvaluation
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
        ),
      ),
      onChanged: (_) {
        if (evaluation != null) setState(() => evaluation = null);
      },
      onSubmitted: (_) => _evaluate(),
    ),
    const SizedBox(height: 8),
    FilledButton.icon(
      key: const Key('evaluatePassword'),
      onPressed: _evaluate,
      icon: const Icon(Icons.security_outlined),
      label: const Text('评估强度'),
    ),
    if (evaluation != null) ...[
      const SizedBox(height: 16),
      _PasswordStrengthCard(result: evaluation!),
    ],
    const SizedBox(height: 16),
    const Text(
      '密码仅在本机内存中分析，不保存、不上传。评分用于发现明显弱模式，不代表绝对安全。',
      style: TextStyle(color: AppColors.muted),
    ),
  ];

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
          setState(() {
            assign(next);
            password = _createPassword();
          });
        },
      );
}

class _PasswordStrengthCard extends StatelessWidget {
  const _PasswordStrengthCard({required this.result});

  final PasswordStrengthResult result;

  @override
  Widget build(BuildContext context) {
    if (!result.isSuccess) {
      return Text(
        result.error!,
        key: const Key('passwordEvaluationError'),
        style: const TextStyle(color: AppColors.danger),
      );
    }
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '强度：${result.level.label}',
              key: const Key('passwordStrengthResult'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(value: (result.score + 1) / 5),
            if (result.warning != null) ...[
              const SizedBox(height: 12),
              Text(
                result.warning!,
                style: const TextStyle(color: AppColors.danger),
              ),
            ],
            for (final suggestion in result.suggestions)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('• $suggestion'),
              ),
          ],
        ),
      ),
    );
  }
}
