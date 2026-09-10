import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/widgets/tool_widgets.dart';
import '../../core/app_theme.dart';
import 'port_reference_logic.dart';

class PortReferenceScreen extends StatefulWidget {
  const PortReferenceScreen({super.key});

  @override
  State<PortReferenceScreen> createState() => _PortReferenceScreenState();
}

class _PortReferenceScreenState extends State<PortReferenceScreen> {
  final _query = TextEditingController();
  PortProtocolFilter _filter = PortProtocolFilter.all;
  List<PortInfo> _results = commonPorts;
  String? _error;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _lookup() {
    setState(() {
      try {
        _results = lookupPorts(_query.text, _filter);
        _error = null;
      } on FormatException catch (error) {
        _results = const [];
        _error = error.message;
      }
    });
  }

  @override
  Widget build(BuildContext context) => ToolPageScaffold(
    title: '端口号参考',
    child: CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          sliver: SliverList.list(
            children: [
              TextField(
                key: const Key('portQuery'),
                controller: _query,
                maxLength: maxPortQueryLength,
                maxLengthEnforcement: MaxLengthEnforcement.none,
                keyboardType: TextInputType.text,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                  labelText: '输入端口号或服务名',
                  prefixIcon: const Icon(Icons.search),
                  errorText: _error,
                ),
                onSubmitted: (_) => _lookup(),
              ),
              SegmentedButton<PortProtocolFilter>(
                segments: const [
                  ButtonSegment(
                    value: PortProtocolFilter.all,
                    label: Text('全部'),
                  ),
                  ButtonSegment(
                    value: PortProtocolFilter.tcp,
                    label: Text('TCP'),
                  ),
                  ButtonSegment(
                    value: PortProtocolFilter.udp,
                    label: Text('UDP'),
                  ),
                ],
                selected: {_filter},
                showSelectedIcon: false,
                onSelectionChanged: (selection) {
                  _filter = selection.first;
                  _lookup();
                },
              ),
              const SizedBox(height: 12),
              FilledButton(
                key: const Key('lookupPort'),
                onPressed: _lookup,
                child: const Text('开始查询'),
              ),
              const SizedBox(height: 12),
              if (_results.isEmpty && _error == null) const Text('内置资料中没有匹配结果'),
            ],
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList.builder(
            itemCount: _results.length,
            itemBuilder: (context, index) {
              final item = _results[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ExpansionTile(
                  title: Row(
                    children: [
                      SizedBox(
                        width: 58,
                        child: Text(
                          '${item.port}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.selected,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.protocol.label,
                          style: const TextStyle(color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(item.service)),
                    ],
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('常见用途：${item.purpose}'),
                    const SizedBox(height: 6),
                    Text('安全提示：${item.advice}'),
                  ],
                ),
              );
            },
          ),
        ),
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 24),
          sliver: SliverToBoxAdapter(
            child: Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                leading: Icon(Icons.shield_outlined, color: AppColors.primary),
                title: Text('仅查询内置资料，不扫描网络'),
                subtitle: Text('结果不代表设备当前端口占用情况'),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
