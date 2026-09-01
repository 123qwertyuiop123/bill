import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../app/widgets/tool_widgets.dart';
import '../../core/app_theme.dart';

/// 本地二维码生成器，不访问相机、网络或相册。
class QrCodeScreen extends StatefulWidget {
  const QrCodeScreen({super.key});

  @override
  State<QrCodeScreen> createState() => _QrCodeScreenState();
}

class _QrCodeScreenState extends State<QrCodeScreen> {
  final controller = TextEditingController();
  String data = '';

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _generate() {
    final value = controller.text.trim();
    if (value.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('请先输入内容')));
      return;
    }
    setState(() => data = value);
  }

  @override
  Widget build(BuildContext context) => ToolPageScaffold(
    title: '二维码生成',
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        TextField(
          controller: controller,
          minLines: 3,
          maxLines: 6,
          maxLength: 1000,
          decoration: const InputDecoration(
            labelText: '文字或网址',
            alignLabelWithHint: true,
          ),
        ),
        FilledButton.icon(
          onPressed: _generate,
          icon: const Icon(Icons.qr_code_2),
          label: const Text('生成二维码'),
        ),
        if (data.isNotEmpty) ...[
          const SizedBox(height: 24),
          Center(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: QrImageView(
                data: data,
                version: QrVersions.auto,
                size: 230,
                errorCorrectionLevel: QrErrorCorrectLevel.M,
                errorStateBuilder: (context, error) => const SizedBox(
                  width: 230,
                  height: 230,
                  child: Center(child: Text('内容过长，无法生成二维码')),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => Clipboard.setData(ClipboardData(text: data)),
            icon: const Icon(Icons.copy_outlined),
            label: const Text('复制原文'),
          ),
        ],
        const SizedBox(height: 12),
        const Text(
          '二维码完全在本机生成，不上传输入内容。',
          style: TextStyle(color: AppColors.muted),
        ),
      ],
    ),
  );
}
