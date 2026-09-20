import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/widgets/tool_widgets.dart';
import '../../core/app_theme.dart';
import 'timestamp_converter_logic.dart';

enum TimestampSection { timestamp, timeZone }

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
  TimestampSection section = TimestampSection.timestamp;
  TimestampToolMode mode = TimestampToolMode.timestampToDate;
  DateTime selectedDateTime = DateTime.now();
  String sourceZoneId = 'Asia/Shanghai';
  String targetZoneId = 'America/New_York';
  TimeZoneConversionResult? timeZoneResult;
  String? error;

  @override
  void dispose() {
    inputController.dispose();
    outputController.dispose();
    super.dispose();
  }

  void _convertTimestamp() {
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

  void _convertTimeZone() {
    final result = convertTimeZone(
      dateTime: selectedDateTime,
      sourceZoneId: sourceZoneId,
      targetZoneId: targetZoneId,
    );
    setState(() {
      timeZoneResult = result;
      error = result.error;
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
      _clearResults();
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
      _clearResults();
    });
  }

  void _clearResults() {
    error = null;
    outputController.clear();
    timeZoneResult = null;
  }

  Future<void> _copyTimestamp() async {
    if (outputController.text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: outputController.text));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('结果已复制')));
  }

  Future<void> _copyTimeZone() async {
    final result = timeZoneResult;
    if (result == null || !result.isSuccess) return;
    final text = _timeZoneResultText(result);
    await Clipboard.setData(ClipboardData(text: text));
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
        SegmentedButton<TimestampSection>(
          segments: const [
            ButtonSegment(
              value: TimestampSection.timestamp,
              label: Text('时间戳'),
            ),
            ButtonSegment(
              value: TimestampSection.timeZone,
              label: Text('时区换算'),
            ),
          ],
          selected: {section},
          showSelectedIcon: false,
          onSelectionChanged: (selection) => setState(() {
            section = selection.first;
            _clearResults();
          }),
        ),
        const SizedBox(height: 20),
        if (section == TimestampSection.timestamp)
          ..._buildTimestampSection(context)
        else
          ..._buildTimeZoneSection(context),
      ],
    ),
  );

  List<Widget> _buildTimestampSection(BuildContext context) => [
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
        _clearResults();
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
          helperText: '自动识别秒和毫秒',
        ),
      )
    else
      _dateTimePicker(context, title: '本地日期时间'),
    if (error != null) _errorText(error!),
    const SizedBox(height: 8),
    FilledButton(
      key: const Key('convertTimestamp'),
      onPressed: _convertTimestamp,
      child: const Text('转换'),
    ),
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
      onPressed: outputController.text.isEmpty ? null : _copyTimestamp,
      icon: const Icon(Icons.copy_outlined),
      label: const Text('复制结果'),
    ),
    const SizedBox(height: 8),
    const Text('日期按设备本地时区显示和换算。', style: TextStyle(color: AppColors.muted)),
  ];

  List<Widget> _buildTimeZoneSection(BuildContext context) => [
    _dateTimePicker(context, title: '日期时间'),
    const SizedBox(height: 16),
    DropdownButtonFormField<String>(
      key: const Key('sourceTimeZone'),
      initialValue: sourceZoneId,
      isExpanded: true,
      decoration: const InputDecoration(labelText: '源时区'),
      items: _timeZoneItems,
      onChanged: (value) {
        if (value == null) return;
        setState(() {
          sourceZoneId = value;
          _clearResults();
        });
      },
    ),
    const SizedBox(height: 16),
    DropdownButtonFormField<String>(
      key: const Key('targetTimeZone'),
      initialValue: targetZoneId,
      isExpanded: true,
      decoration: const InputDecoration(labelText: '目标时区'),
      items: _timeZoneItems,
      onChanged: (value) {
        if (value == null) return;
        setState(() {
          targetZoneId = value;
          _clearResults();
        });
      },
    ),
    if (error != null) _errorText(error!),
    const SizedBox(height: 16),
    FilledButton.icon(
      key: const Key('convertTimeZone'),
      onPressed: _convertTimeZone,
      icon: const Icon(Icons.public_outlined),
      label: const Text('开始换算'),
    ),
    if (timeZoneResult?.isSuccess ?? false) ...[
      const SizedBox(height: 16),
      _timeZoneResultCard(context, timeZoneResult!),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        onPressed: _copyTimeZone,
        icon: const Icon(Icons.copy_outlined),
        label: const Text('复制结果'),
      ),
    ],
    const SizedBox(height: 12),
    const Text(
      '按内置 IANA 时区规则离线换算；时区规则会随应用版本更新。',
      style: TextStyle(color: AppColors.muted),
    ),
  ];

  List<DropdownMenuItem<String>> get _timeZoneItems => [
    for (final zone in commonTimeZones)
      DropdownMenuItem(value: zone.id, child: Text(zone.label)),
  ];

  Widget _dateTimePicker(BuildContext context, {required String title}) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) => Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                SizedBox(
                  width: constraints.maxWidth >= 420
                      ? (constraints.maxWidth - 10) / 2
                      : constraints.maxWidth,
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Text(_formatDate(selectedDateTime)),
                  ),
                ),
                SizedBox(
                  width: constraints.maxWidth >= 420
                      ? (constraints.maxWidth - 10) / 2
                      : constraints.maxWidth,
                  child: OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.schedule_outlined),
                    label: Text(_formatTime(selectedDateTime)),
                  ),
                ),
              ],
            ),
          ),
        ],
      );

  Widget _timeZoneResultCard(
    BuildContext context,
    TimeZoneConversionResult result,
  ) => Card(
    key: const Key('timeZoneResult'),
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('换算结果', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          SelectableText(_timeZoneResultText(result)),
          if (result.transitionNotice != null) ...[
            const SizedBox(height: 12),
            Text(
              result.transitionNotice!,
              style: const TextStyle(color: AppColors.muted),
            ),
          ],
        ],
      ),
    ),
  );

  String _timeZoneResultText(TimeZoneConversionResult result) =>
      '源时区（${result.sourceZoneId}）\n'
      '${formatZonedDateTime(result.source!)}  ${formatUtcOffset(result.source!.timeZoneOffset)}\n\n'
      '目标时区（${result.targetZoneId}）\n'
      '${formatZonedDateTime(result.target!)}  ${formatUtcOffset(result.target!.timeZoneOffset)}';

  Widget _errorText(String message) => Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 4),
    child: Text(message, style: const TextStyle(color: AppColors.danger)),
  );

  String _formatDate(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  String _formatTime(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}
