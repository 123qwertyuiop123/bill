import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/widgets/tool_widgets.dart';
import '../../core/app_theme.dart';
import 'random_decision_logic.dart';

enum RandomMode { number, dice, coin, list }

class RandomDecisionScreen extends StatefulWidget {
  const RandomDecisionScreen({super.key});

  @override
  State<RandomDecisionScreen> createState() => _RandomDecisionScreenState();
}

class _RandomDecisionScreenState extends State<RandomDecisionScreen> {
  RandomMode mode = RandomMode.list;
  final optionsController = TextEditingController(text: '火锅\n面条\n米饭\n沙拉');
  final minController = TextEditingController(text: '1');
  final maxController = TextEditingController(text: '100');
  String result = '点击按钮生成结果';

  @override
  void dispose() {
    optionsController.dispose();
    minController.dispose();
    maxController.dispose();
    super.dispose();
  }

  void _generate() {
    final random = Random.secure();
    String? next;
    switch (mode) {
      case RandomMode.number:
        final min = int.tryParse(minController.text);
        final max = int.tryParse(maxController.text);
        final value = min == null || max == null
            ? null
            : secureRandomInt(min, max, random: random);
        next = value?.toString();
      case RandomMode.dice:
        next = '骰子点数：${random.nextInt(6) + 1}';
      case RandomMode.coin:
        next = random.nextBool() ? '正面' : '反面';
      case RandomMode.list:
        next = chooseRandom(
          optionsController.text.split(RegExp(r'[\n,，]+')),
          random: random,
        );
    }
    setState(() => result = next ?? '请输入有效内容');
  }

  @override
  Widget build(BuildContext context) => ToolPageScaffold(
    title: '随机决定',
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _chip(RandomMode.number, '随机数'),
            _chip(RandomMode.dice, '骰子'),
            _chip(RandomMode.coin, '硬币'),
            _chip(RandomMode.list, '名单抽取'),
          ],
        ),
        const SizedBox(height: 16),
        if (mode == RandomMode.list)
          TextField(
            controller: optionsController,
            minLines: 5,
            maxLines: 10,
            maxLength: 10000,
            decoration: const InputDecoration(
              labelText: '候选项',
              helperText: '每行一个，也可以用逗号分隔',
            ),
          )
        else if (mode == RandomMode.number)
          Row(
            children: [
              Expanded(child: _integerField(minController, '最小值')),
              const SizedBox(width: 10),
              Expanded(child: _integerField(maxController, '最大值')),
            ],
          )
        else
          SizedBox(
            height: 180,
            child: Center(
              child: Icon(
                mode == RandomMode.dice
                    ? Icons.casino_outlined
                    : Icons.paid_outlined,
                size: 72,
                color: AppColors.muted,
              ),
            ),
          ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          color: AppColors.selected,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Text('本次结果'),
                const SizedBox(height: 10),
                SelectableText(
                  result,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: _generate,
          icon: const Icon(Icons.shuffle),
          label: Text(result == '点击按钮生成结果' ? '开始抽取' : '再抽一次'),
        ),
      ],
    ),
  );

  Widget _chip(RandomMode value, String label) => ChoiceChip(
    label: Text(label),
    selected: mode == value,
    onSelected: (_) => setState(() {
      mode = value;
      result = '点击按钮生成结果';
    }),
  );

  Widget _integerField(TextEditingController controller, String label) =>
      TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(signed: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'-?[0-9]*')),
        ],
        decoration: InputDecoration(labelText: label),
      );
}
