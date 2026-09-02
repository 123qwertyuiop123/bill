import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/widgets/tool_widgets.dart';
import '../../core/app_theme.dart';
import 'jwt_viewer_logic.dart';

enum JwtSection { header, payload }

class JwtViewerScreen extends StatefulWidget {
  const JwtViewerScreen({super.key});

  @override
  State<JwtViewerScreen> createState() => _JwtViewerScreenState();
}

class _JwtViewerScreenState extends State<JwtViewerScreen> {
  final inputController = TextEditingController(
    text:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
        'eyJzdWIiOiIxMjMiLCJuYW1lIjoiVGVzdCBVc2VyIiwiaWF0IjoxNzIxNjQ4ODAwLCJleHAiOjQxMDI0NDQ4MDB9.'
        'signature',
  );
  final outputController = TextEditingController();
  JwtSection section = JwtSection.payload;
  JwtViewerResult? result;

  @override
  void dispose() {
    inputController.dispose();
    outputController.dispose();
    super.dispose();
  }

  void _parse() {
    final next = parseJwtForViewing(inputController.text);
    setState(() {
      result = next;
      _syncOutput(next);
    });
  }

  void _selectSection(JwtSection next) => setState(() {
    section = next;
    if (result != null) _syncOutput(result!);
  });

  void _syncOutput(JwtViewerResult value) {
    outputController.text = value.isSuccess
        ? section == JwtSection.header
              ? value.headerText
              : value.payloadText
        : '';
  }

  Future<void> _copy() async {
    if (outputController.text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: outputController.text));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('解析结果已复制')));
  }

  @override
  Widget build(BuildContext context) => ToolPageScaffold(
    title: 'JWT 查看',
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xfffff3dc),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Color(0xffa96800)),
              SizedBox(width: 8),
              Expanded(child: Text('仅解析结构，不验证签名')),
            ],
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          key: const Key('jwtInput'),
          controller: inputController,
          minLines: 5,
          maxLines: 8,
          maxLength: maxJwtInputLength,
          decoration: const InputDecoration(
            labelText: 'JWT Token',
            alignLabelWithHint: true,
          ),
        ),
        if (result?.error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              result!.error!,
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
        FilledButton(onPressed: _parse, child: const Text('解析')),
        const SizedBox(height: 14),
        SegmentedButton<JwtSection>(
          segments: const [
            ButtonSegment(value: JwtSection.header, label: Text('Header')),
            ButtonSegment(value: JwtSection.payload, label: Text('Payload')),
          ],
          selected: {section},
          showSelectedIcon: false,
          onSelectionChanged: (selection) => _selectSection(selection.first),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('jwtOutput'),
          controller: outputController,
          readOnly: true,
          minLines: 8,
          maxLines: 14,
          decoration: InputDecoration(
            labelText: section == JwtSection.header
                ? 'Header JSON'
                : 'Payload JSON',
            alignLabelWithHint: true,
            suffixIcon: IconButton(
              tooltip: '复制',
              onPressed: outputController.text.isEmpty ? null : _copy,
              icon: const Icon(Icons.copy_outlined),
            ),
          ),
        ),
        if (result?.isSuccess ?? false) ...[
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              title: const Text('有效期状态'),
              trailing: Text(
                result!.expiryStatus,
                key: const Key('jwtExpiryStatus'),
              ),
            ),
          ),
        ],
        const SizedBox(height: 8),
        const Text(
          '解析结果来自未验证输入，不代表令牌真实、有效或可信。',
          style: TextStyle(color: AppColors.muted),
        ),
      ],
    ),
  );
}
