import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/widgets/tool_result_widgets.dart';
import '../../app/widgets/tool_widgets.dart';
import '../../core/app_theme.dart';
import 'mime_type_reference_logic.dart';

class MimeTypeReferenceScreen extends StatefulWidget {
  const MimeTypeReferenceScreen({super.key});

  @override
  State<MimeTypeReferenceScreen> createState() =>
      _MimeTypeReferenceScreenState();
}

class _MimeTypeReferenceScreenState extends State<MimeTypeReferenceScreen> {
  final _query = TextEditingController(text: '.json');
  MimeLookupMode _mode = MimeLookupMode.extension;
  List<MimeTypeInfo> _results = const [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _lookup();
  }

  void _lookup() {
    setState(() {
      _error = null;
      try {
        _results = lookupMimeTypes(_query.text, _mode);
      } on FormatException catch (error) {
        _results = const [];
        _error = error.message;
      }
    });
  }

  void _changeMode(MimeLookupMode mode) {
    setState(() {
      _mode = mode;
      _query.text = mode == MimeLookupMode.extension
          ? '.json'
          : 'application/json';
    });
    _lookup();
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ToolPageScaffold(
    title: 'MIME 类型',
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('按扩展名或媒体类型离线查询'),
        const SizedBox(height: 16),
        SegmentedButton<MimeLookupMode>(
          segments: const [
            ButtonSegment(value: MimeLookupMode.extension, label: Text('按扩展名')),
            ButtonSegment(value: MimeLookupMode.mime, label: Text('按 MIME')),
          ],
          selected: {_mode},
          showSelectedIcon: false,
          onSelectionChanged: (selection) => _changeMode(selection.first),
        ),
        const SizedBox(height: 16),
        TextField(
          key: const Key('mimeQuery'),
          controller: _query,
          maxLength: maxMimeQueryLength,
          maxLengthEnforcement: MaxLengthEnforcement.none,
          autocorrect: false,
          enableSuggestions: false,
          decoration: InputDecoration(
            labelText: _mode == MimeLookupMode.extension ? '文件扩展名' : 'MIME 类型',
            errorText: _error,
            errorMaxLines: 3,
          ),
          onSubmitted: (_) => _lookup(),
        ),
        FilledButton(
          key: const Key('lookupMime'),
          onPressed: _lookup,
          child: const Text('开始查询'),
        ),
        const SizedBox(height: 16),
        if (_results.isEmpty && _error == null)
          const Text('内置表中没有匹配结果')
        else
          for (final item in _results) ...[
            ToolResultCard(
              values: {
                'MIME 类型': item.mime,
                '常见扩展名': item.extensionsLabel,
                '类别': item.category,
                '是否文本': item.isText ? '是' : '否',
              },
            ),
            const SizedBox(height: 8),
            CopyResultButton(text: item.mime),
            const SizedBox(height: 12),
          ],
        const Text('仅按内置表查询，不读取文件内容', style: TextStyle(color: AppColors.muted)),
      ],
    ),
  );
}
