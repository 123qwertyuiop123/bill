import 'package:flutter/material.dart';

import '../chmod_calculator_logic.dart';

/// 大字体或窄屏允许横向滚动，保持复选框触控区域和完整中文语义。
class PermissionMatrix extends StatelessWidget {
  const PermissionMatrix({
    required this.value,
    required this.onToggle,
    super.key,
  });
  final UnixPermissions? value;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    const owners = ['所有者', '用户组', '其他人'];
    const rights = ['读取', '写入', '执行'];
    return Card(
      margin: EdgeInsets.zero,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          horizontalMargin: 12,
          columnSpacing: 16,
          columns: [
            const DataColumn(label: Text('对象')),
            for (final right in rights) DataColumn(label: Text(right)),
          ],
          rows: [
            for (var row = 0; row < 3; row++)
              DataRow(
                cells: [
                  DataCell(Text(owners[row])),
                  for (var col = 0; col < 3; col++)
                    DataCell(
                      Semantics(
                        label: '${owners[row]}${rights[col]}',
                        child: Checkbox(
                          key: Key('permission${row * 3 + col}'),
                          value: value?.enabled(row * 3 + col) ?? false,
                          onChanged: value == null
                              ? null
                              : (_) => onToggle(row * 3 + col),
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
