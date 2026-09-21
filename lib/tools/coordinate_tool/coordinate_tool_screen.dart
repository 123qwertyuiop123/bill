import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/widgets/tool_widgets.dart';
import '../../core/app_theme.dart';
import 'coordinate_tool_logic.dart';

enum _CoordinateMode { conversion, distance }

enum _ConversionDirection { decimalToDms, dmsToDecimal }

/// 所有坐标均由用户手动输入；页面不会读取定位、文件或网络数据。
class CoordinateToolScreen extends StatefulWidget {
  const CoordinateToolScreen({super.key});

  @override
  State<CoordinateToolScreen> createState() => _CoordinateToolScreenState();
}

class _CoordinateToolScreenState extends State<CoordinateToolScreen> {
  final decimalController = TextEditingController(text: '31.2304');
  final degreesController = TextEditingController(text: '31');
  final minutesController = TextEditingController(text: '13');
  final secondsController = TextEditingController(text: '49.44');
  final startLatitudeController = TextEditingController(text: '31.2304');
  final startLongitudeController = TextEditingController(text: '121.4737');
  final endLatitudeController = TextEditingController(text: '39.9042');
  final endLongitudeController = TextEditingController(text: '116.4074');

  _CoordinateMode mode = _CoordinateMode.conversion;
  _ConversionDirection direction = _ConversionDirection.decimalToDms;
  CoordinateAxis axis = CoordinateAxis.latitude;
  String hemisphere = '北纬';
  CoordinateConversionResult? conversionResult;
  CoordinateDistanceResult? distanceResult;

  @override
  void dispose() {
    decimalController.dispose();
    degreesController.dispose();
    minutesController.dispose();
    secondsController.dispose();
    startLatitudeController.dispose();
    startLongitudeController.dispose();
    endLatitudeController.dispose();
    endLongitudeController.dispose();
    super.dispose();
  }

  void _changeAxis(CoordinateAxis? value) {
    if (value == null) return;
    setState(() {
      axis = value;
      hemisphere = axis.hemispheres.first;
      conversionResult = null;
    });
  }

  void _calculate() => setState(() {
    if (mode == _CoordinateMode.conversion) {
      conversionResult = direction == _ConversionDirection.decimalToDms
          ? decimalToDms(decimalController.text, axis)
          : dmsToDecimal(
              degreesInput: degreesController.text,
              minutesInput: minutesController.text,
              secondsInput: secondsController.text,
              axis: axis,
              hemisphere: hemisphere,
            );
    } else {
      distanceResult = calculateCoordinateDistance(
        startLatitude: startLatitudeController.text,
        startLongitude: startLongitudeController.text,
        endLatitude: endLatitudeController.text,
        endLongitude: endLongitudeController.text,
      );
    }
  });

  @override
  Widget build(BuildContext context) {
    final error = mode == _CoordinateMode.conversion
        ? conversionResult?.error
        : distanceResult?.error;
    return ToolPageScaffold(
      title: '地理坐标',
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SegmentedButton<_CoordinateMode>(
            segments: const [
              ButtonSegment(
                value: _CoordinateMode.conversion,
                label: Text('坐标转换'),
              ),
              ButtonSegment(
                value: _CoordinateMode.distance,
                label: Text('距离方位'),
              ),
            ],
            selected: {mode},
            showSelectedIcon: false,
            onSelectionChanged: (selection) => setState(() {
              mode = selection.first;
              conversionResult = null;
              distanceResult = null;
            }),
          ),
          const SizedBox(height: 16),
          if (mode == _CoordinateMode.conversion)
            _buildConversionInputs()
          else
            _buildDistanceInputs(),
          if (error != null) ...[
            const SizedBox(height: 12),
            Text(error, style: const TextStyle(color: AppColors.danger)),
          ],
          const SizedBox(height: 16),
          FilledButton(
            key: const Key('calculateCoordinate'),
            onPressed: _calculate,
            child: Text(
              mode == _CoordinateMode.conversion ? '转换坐标' : '计算距离与方位',
            ),
          ),
          if (conversionResult?.isSuccess ?? false) ...[
            const SizedBox(height: 16),
            _ConversionResultCard(
              result: conversionResult!,
              direction: direction,
            ),
          ],
          if (distanceResult?.isSuccess ?? false) ...[
            const SizedBox(height: 16),
            _DistanceResultCard(result: distanceResult!),
          ],
          const SizedBox(height: 12),
          const Text(
            '仅按 WGS84 平均地球半径进行球面近似，不读取设备位置，不用于测绘或导航。',
            style: TextStyle(color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  Widget _buildConversionInputs() => Column(
    children: [
      SegmentedButton<_ConversionDirection>(
        segments: const [
          ButtonSegment(
            value: _ConversionDirection.decimalToDms,
            label: Text('十进制度转度分秒'),
          ),
          ButtonSegment(
            value: _ConversionDirection.dmsToDecimal,
            label: Text('度分秒转十进制度'),
          ),
        ],
        selected: {direction},
        showSelectedIcon: false,
        onSelectionChanged: (selection) => setState(() {
          direction = selection.first;
          conversionResult = null;
        }),
      ),
      const SizedBox(height: 16),
      DropdownButtonFormField<CoordinateAxis>(
        initialValue: axis,
        decoration: const InputDecoration(labelText: '坐标类型'),
        items: CoordinateAxis.values
            .map(
              (item) => DropdownMenuItem(value: item, child: Text(item.label)),
            )
            .toList(),
        onChanged: _changeAxis,
      ),
      const SizedBox(height: 12),
      if (direction == _ConversionDirection.decimalToDms)
        _numberField(decimalController, '十进制度，例如 31.2304')
      else ...[
        LayoutBuilder(
          builder: (context, constraints) {
            final fields = [
              _numberField(degreesController, '度'),
              _numberField(minutesController, '分'),
              _numberField(secondsController, '秒'),
            ];
            if (constraints.maxWidth < 430) {
              return Column(
                children: [
                  for (var index = 0; index < fields.length; index++) ...[
                    fields[index],
                    if (index < fields.length - 1) const SizedBox(height: 10),
                  ],
                ],
              );
            }
            return Row(
              children: [
                for (var index = 0; index < fields.length; index++) ...[
                  Expanded(child: fields[index]),
                  if (index < fields.length - 1) const SizedBox(width: 10),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: hemisphere,
          decoration: const InputDecoration(labelText: '方向'),
          items: axis.hemispheres
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              hemisphere = value;
              conversionResult = null;
            });
          },
        ),
      ],
    ],
  );

  Widget _buildDistanceInputs() => Column(
    children: [
      _numberField(startLatitudeController, '起点纬度（-90 到 90）'),
      const SizedBox(height: 12),
      _numberField(startLongitudeController, '起点经度（-180 到 180）'),
      const SizedBox(height: 12),
      _numberField(endLatitudeController, '终点纬度（-90 到 90）'),
      const SizedBox(height: 12),
      _numberField(endLongitudeController, '终点经度（-180 到 180）'),
    ],
  );

  Widget _numberField(TextEditingController controller, String label) =>
      TextField(
        controller: controller,
        maxLength: maxCoordinateInputLength,
        // 坐标必须保留原始粘贴内容，由业务校验明确拒绝单位符号或超长文本。
        maxLengthEnforcement: MaxLengthEnforcement.none,
        keyboardType: const TextInputType.numberWithOptions(
          decimal: true,
          signed: true,
        ),
        decoration: InputDecoration(labelText: label, counterText: ''),
        onChanged: (_) => setState(() {
          conversionResult = null;
          distanceResult = null;
        }),
      );
}

class _ConversionResultCard extends StatelessWidget {
  const _ConversionResultCard({required this.result, required this.direction});

  final CoordinateConversionResult result;
  final _ConversionDirection direction;

  @override
  Widget build(BuildContext context) {
    final text = direction == _ConversionDirection.decimalToDms
        ? result.dms!
        : result.decimal!
              .toStringAsFixed(8)
              .replaceFirst(RegExp(r'\.?0+$'), '');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('转换结果', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            SelectableText(
              text,
              key: const Key('coordinateConversionResult'),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _DistanceResultCard extends StatelessWidget {
  const _DistanceResultCard({required this.result});

  final CoordinateDistanceResult result;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('计算结果', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Text(
            '大圆距离  ${result.distanceKm!.toStringAsFixed(3)} 千米',
            key: const Key('coordinateDistanceResult'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const Divider(height: 24),
          Text(
            result.hasUniqueBearing
                ? '初始方位  ${result.initialBearing!.toStringAsFixed(1)}°（${result.direction}）'
                : '初始方位  ${result.direction ?? '无法确定'}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    ),
  );
}
