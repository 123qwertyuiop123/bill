import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/widgets/tool_widgets.dart';
import '../../core/app_theme.dart';
import 'timestamp_converter_logic.dart';

enum TimestampToolMode { timestampToDate, dateToTimestamp }

class TimestampConverterScreen extends StatefulWidget {
  const TimestampConverterScreen({super.key});

  @override
  State<TimestampConverterScreen> createState() =>
      _TimestampConverterScreenState();
}

class _TimestampConverterScreenState extends State<TimestampConverterScreen> {
  final inputController = TextEditingController(text: '1725148800');
  final outputController = TextEditingController();
  TimestampToolMode mode = TimestampToolMode.timestampToDate;
  DateTime selectedDateTime = DateTime.now();
  String? error;

  @override
  void dispose() {
    inputController.dispose();
    outputController.dispose();
    super.dispose();
  }

  void _convert() {
    final result = mode == TimestampToolMode.timestampToDate
        ? parseUnixTimestamp(inputController.text)
        : convertDateToTimestamp(selectedDateTime);
    setState(() {
      error = result.error;
      outputController.text = result.isSuccess
          ? '本地时间：${formatLocalDateTime(result.dateTime!)}\n'
                '秒：${result.seconds}\n毫秒：${result.milliseconds}'
          : '';
    });
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDateTime,
      firstDate: DateTime(minTimestampYear),
      lastDate: DateTime(maxTimestampYear, 12, 31),
    );
    if (date == null || !mounted) return;
    setState(() {
      selectedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        selectedDateTime.hour,
        selectedDateTime.minute,
        selectedDateTime.second,
      );
      outputController.clear();
    });
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(selectedDateTime),
    );
    if (time == null || !mounted) return;
    setState(() {
      selectedDateTime = DateTime(
        selectedDateTime.year,
        selectedDateTime.month,
        selectedDateTime.day,
        time.hour,
        time.minute,
      );
      outputController.clear();
    });
  }

  Future<void> _copy() async {
    if (outputController.text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: outputController.text));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('结果已复制')));
  }

  @override
  Widget build(BuildContext context) => ToolPageScaffold(
    title: 'Unix 时间戳',
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        SegmentedButton<TimestampToolMode>(
          segments: const [
            ButtonSegment(
              value: TimestampToolMode.timestampToDate,
              label: Text('时间戳 → 日期'),
            ),
            ButtonSegment(
              value: TimestampToolMode.dateToTimestamp,
              label: Text('日期 → 时间戳'),
            ),
          ],
          selected: {mode},
          showSelectedIcon: false,
          onSelectionChanged: (selection) => setState(() {
            mode = selection.first;
            error = null;
            outputController.clear();
          }),
        ),
        const SizedBox(height: 20),
        if (mode == TimestampToolMode.timestampToDate)
          TextField(
            key: const Key('timestampInput'),
            controller: inputController,
            keyboardType: const TextInputType.numberWithOptions(signed: true),
            maxLength: 16,
            decoration: const InputDecoration(
              labelText: '秒或毫秒时间戳',
              helperText: '自动识别 10 位秒和 13 位毫秒',
            ),
          )
        else ...[
          Text('本地日期时间', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text(
                    '${selectedDateTime.year}-${selectedDateTime.month.toString().padLeft(2, '0')}-${selectedDateTime.day.toString().padLeft(2, '0')}',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickTime,
                  icon: const Icon(Icons.schedule_outlined),
                  label: Text(
                    '${selectedDateTime.hour.toString().padLeft(2, '0')}:${selectedDateTime.minute.toString().padLeft(2, '0')}',
                  ),
                ),
              ),
            ],
          ),
        ],
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 12),
            child: Text(
              error!,
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
        const SizedBox(height: 8),
        FilledButton(onPressed: _convert, child: const Text('转换')),
        const SizedBox(height: 16),
        TextField(
          key: const Key('timestampOutput'),
          controller: outputController,
          readOnly: true,
          minLines: 4,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: '转换结果',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: outputController.text.isEmpty ? null : _copy,
          icon: const Icon(Icons.copy_outlined),
          label: const Text('复制结果'),
        ),
        const SizedBox(height: 8),
        const Text('日期按设备本地时区显示和换算。', style: TextStyle(color: AppColors.muted)),
      ],
    ),
  );
}
