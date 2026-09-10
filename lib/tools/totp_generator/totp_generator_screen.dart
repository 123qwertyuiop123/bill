import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/widgets/tool_result_widgets.dart';
import '../../app/widgets/tool_widgets.dart';
import '../../core/app_theme.dart';
import 'totp_generator_logic.dart';

class TotpGeneratorScreen extends StatefulWidget {
  const TotpGeneratorScreen({super.key});

  @override
  State<TotpGeneratorScreen> createState() => _TotpGeneratorScreenState();
}

class _TotpGeneratorScreenState extends State<TotpGeneratorScreen> {
  final _secret = TextEditingController();
  TotpAlgorithm _algorithm = TotpAlgorithm.sha1;
  int _digits = 6;
  int _period = 30;
  bool _obscureSecret = true;
  TotpResult? _result;
  String? _error;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    // 页面退出时释放敏感输入，不写入任何持久化位置。
    _secret.clear();
    _secret.dispose();
    super.dispose();
  }

  void _invalidate() {
    _timer?.cancel();
    setState(() {
      _result = null;
      _error = null;
    });
  }

  void _generate({bool startTimer = true}) {
    try {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final result = generateTotp(
        secret: _secret.text,
        timestampSeconds: now,
        algorithm: _algorithm,
        digits: _digits,
        period: _period,
      );
      setState(() {
        _result = result;
        _error = null;
      });
      if (startTimer) {
        _timer?.cancel();
        _timer = Timer.periodic(const Duration(seconds: 1), (_) {
          if (mounted) _generate(startTimer: false);
        });
      }
    } on FormatException catch (error) {
      _timer?.cancel();
      setState(() {
        _result = null;
        _error = error.message;
      });
    }
  }

  String _displayCode(String code) => code.length == 6
      ? '${code.substring(0, 3)} ${code.substring(3)}'
      : '${code.substring(0, 4)} ${code.substring(4)}';

  @override
  Widget build(BuildContext context) => ToolPageScaffold(
    title: 'TOTP 验证码',
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  key: const Key('totpSecret'),
                  controller: _secret,
                  obscureText: _obscureSecret,
                  maxLength: maxTotpSecretLength,
                  maxLengthEnforcement: MaxLengthEnforcement.none,
                  autocorrect: false,
                  enableSuggestions: false,
                  keyboardType: TextInputType.visiblePassword,
                  decoration: InputDecoration(
                    labelText: 'Base32 密钥',
                    errorText: _error,
                    errorMaxLines: 3,
                    suffixIcon: IconButton(
                      key: const Key('toggleTotpSecret'),
                      tooltip: _obscureSecret ? '显示密钥' : '隐藏密钥',
                      onPressed: () =>
                          setState(() => _obscureSecret = !_obscureSecret),
                      icon: Icon(
                        _obscureSecret
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  onChanged: (_) => _invalidate(),
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final fields = <Widget>[
                      _algorithmField(),
                      _numberField(
                        label: '位数',
                        value: _digits,
                        values: const [6, 8],
                        suffix: ' 位',
                        onChanged: (value) {
                          _digits = value;
                          _invalidate();
                        },
                      ),
                      _numberField(
                        label: '周期',
                        value: _period,
                        values: const [30, 60],
                        suffix: ' 秒',
                        onChanged: (value) {
                          _period = value;
                          _invalidate();
                        },
                      ),
                    ];
                    if (constraints.maxWidth < 430) {
                      return Column(
                        children: [
                          for (var i = 0; i < fields.length; i++) ...[
                            fields[i],
                            if (i < fields.length - 1)
                              const SizedBox(height: 10),
                          ],
                        ],
                      );
                    }
                    return Row(
                      children: [
                        for (var i = 0; i < fields.length; i++) ...[
                          Expanded(child: fields[i]),
                          if (i < fields.length - 1) const SizedBox(width: 8),
                        ],
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: const Key('generateTotp'),
                    onPressed: _generate,
                    child: const Text('生成验证码'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_result case final result?)
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '验证码',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SelectableText(
                    _displayCode(result.code),
                    key: const Key('totpCode'),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('${result.remainingSeconds} 秒后更新'),
                  const SizedBox(height: 12),
                  CopyResultButton(text: result.code),
                ],
              ),
            ),
          )
        else
          const Text('输入密钥并点击“生成验证码”'),
        const SizedBox(height: 16),
        const Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            leading: Icon(Icons.shield_outlined, color: AppColors.primary),
            title: Text('密钥仅保留在当前页面'),
            subtitle: Text('验证码依赖设备时间，请确保系统时间准确'),
          ),
        ),
      ],
    ),
  );

  Widget _algorithmField() => DropdownButtonFormField<TotpAlgorithm>(
    initialValue: _algorithm,
    isExpanded: true,
    decoration: const InputDecoration(labelText: '算法'),
    items: [
      for (final algorithm in TotpAlgorithm.values)
        DropdownMenuItem(value: algorithm, child: Text(algorithm.label)),
    ],
    onChanged: (value) {
      if (value == null) return;
      _algorithm = value;
      _invalidate();
    },
  );

  Widget _numberField({
    required String label,
    required int value,
    required List<int> values,
    required String suffix,
    required ValueChanged<int> onChanged,
  }) => DropdownButtonFormField<int>(
    initialValue: value,
    isExpanded: true,
    decoration: InputDecoration(labelText: label),
    items: [
      for (final item in values)
        DropdownMenuItem(value: item, child: Text('$item$suffix')),
    ],
    onChanged: (selected) {
      if (selected != null) onChanged(selected);
    },
  );
}
