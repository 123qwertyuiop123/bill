import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/widgets/tool_widgets.dart';
import '../../core/app_theme.dart';
import 'http_status_reference_logic.dart';

class HttpStatusReferenceScreen extends StatefulWidget {
  const HttpStatusReferenceScreen({super.key});

  @override
  State<HttpStatusReferenceScreen> createState() =>
      _HttpStatusReferenceScreenState();
}

class _HttpStatusReferenceScreenState extends State<HttpStatusReferenceScreen> {
  final _query = TextEditingController(text: '404');
  HttpStatusGroup _group = HttpStatusGroup.all;
  List<HttpStatusInfo> _results = const [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _search();
  }

  void _search() {
    setState(() {
      _error = null;
      try {
        _results = searchHttpStatuses(_query.text, _group);
      } on FormatException catch (error) {
        _results = const [];
        _error = error.message;
      }
    });
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ToolPageScaffold(
    title: 'HTTP 状态码',
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('离线查询常用 HTTP 状态含义'),
        const SizedBox(height: 16),
        TextField(
          key: const Key('httpStatusQuery'),
          controller: _query,
          maxLength: 64,
          maxLengthEnforcement: MaxLengthEnforcement.none,
          decoration: InputDecoration(
            labelText: '输入状态码或关键词',
            prefixIcon: const Icon(Icons.search),
            errorText: _error,
          ),
          onSubmitted: (_) => _search(),
        ),
        Wrap(
          spacing: 8,
          children: [
            for (final group in HttpStatusGroup.values)
              ChoiceChip(
                label: Text(group.label),
                selected: _group == group,
                onSelected: (_) {
                  _group = group;
                  _search();
                },
              ),
          ],
        ),
        const SizedBox(height: 12),
        FilledButton(
          key: const Key('searchHttpStatus'),
          onPressed: _search,
          child: const Text('开始查询'),
        ),
        const SizedBox(height: 16),
        if (_results.isEmpty && _error == null)
          const Text('没有找到匹配的状态码')
        else
          for (final item in _results) ...[
            _StatusCard(item: item),
            const SizedBox(height: 12),
          ],
        const Text('离线参考，不会发送网络请求', style: TextStyle(color: AppColors.muted)),
      ],
    ),
  );
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.item});

  final HttpStatusInfo item;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              SelectableText(
                '${item.code} ${item.reason}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Chip(label: Text(item.category)),
            ],
          ),
          const SizedBox(height: 8),
          Text(item.description),
          const Divider(height: 24),
          _InfoRow(label: '常见场景', value: item.scenario),
          const SizedBox(height: 8),
          _InfoRow(label: '处理建议', value: item.suggestion),
        ],
      ),
    ),
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: AppColors.muted)),
      const SizedBox(height: 4),
      Text(value),
    ],
  );
}
