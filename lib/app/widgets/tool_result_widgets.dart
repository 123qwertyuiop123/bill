import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 只在主动点击时写剪贴板；失败不暴露平台异常或用户内容。
class CopyResultButton extends StatefulWidget {
  const CopyResultButton({required this.text, super.key});
  final String text;

  @override
  State<CopyResultButton> createState() => _CopyResultButtonState();
}

class _CopyResultButtonState extends State<CopyResultButton> {
  bool _busy = false;

  Future<void> _copy() async {
    if (_busy || widget.text.isEmpty) return;
    setState(() => _busy = true);
    var message = '已复制';
    try {
      await Clipboard.setData(ClipboardData(text: widget.text));
    } catch (_) {
      message = '复制失败，请重试';
    }
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: widget.text.isEmpty || _busy ? null : _copy,
    child: const Text('复制结果'),
  );
}

/// 结果在窄屏或大字体下纵向排列，避免标签和长数字相互挤压。
class ToolResultCard extends StatelessWidget {
  const ToolResultCard({required this.values, super.key});
  final Map<String, String> values;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final entry in values.entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: 16,
                runSpacing: 6,
                children: [Text(entry.key), SelectableText(entry.value)],
              ),
            ),
        ],
      ),
    ),
  );
}
