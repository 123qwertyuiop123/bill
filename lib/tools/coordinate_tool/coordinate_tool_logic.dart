import 'dart:math' as math;

const maxCoordinateInputLength = 32;
const _earthMeanRadiusKm = 6371.0088;

enum CoordinateAxis { latitude, longitude }

extension CoordinateAxisLabel on CoordinateAxis {
  String get label => switch (this) {
    CoordinateAxis.latitude => '纬度',
    CoordinateAxis.longitude => '经度',
  };

  double get limit => this == CoordinateAxis.latitude ? 90 : 180;

  List<String> get hemispheres =>
      this == CoordinateAxis.latitude ? const ['北纬', '南纬'] : const ['东经', '西经'];
}

class CoordinateConversionResult {
  const CoordinateConversionResult({this.decimal, this.dms, this.error});

  final double? decimal;
  final String? dms;
  final String? error;
  bool get isSuccess => error == null;
}

class CoordinateDistanceResult {
  const CoordinateDistanceResult({
    this.distanceKm,
    this.initialBearing,
    this.direction,
    this.error,
  });

  final double? distanceKm;
  final double? initialBearing;
  final String? direction;
  final String? error;
  bool get isSuccess => error == null;
  bool get hasUniqueBearing => initialBearing != null;
}

/// 把十进制度转换为度分秒。边界值会进位，避免显示 60 秒或 60 分。
CoordinateConversionResult decimalToDms(String input, CoordinateAxis axis) {
  final value = _parseBoundedCoordinate(input, axis, axis.label);
  if (value.error != null) {
    return CoordinateConversionResult(error: value.error);
  }
  final decimal = value.value!;
  var degrees = decimal.abs().floor();
  final minuteValue = (decimal.abs() - degrees) * 60;
  var minutes = minuteValue.floor();
  var seconds = (minuteValue - minutes) * 60;
  seconds = double.parse(seconds.toStringAsFixed(4));
  if (seconds >= 60) {
    seconds = 0;
    minutes++;
  }
  if (minutes >= 60) {
    minutes = 0;
    degrees++;
  }
  final hemisphere = axis == CoordinateAxis.latitude
      ? (decimal < 0 ? '南纬' : '北纬')
      : (decimal < 0 ? '西经' : '东经');
  return CoordinateConversionResult(
    decimal: decimal,
    dms: '$hemisphere $degrees° $minutes′ ${_formatNumber(seconds)}″',
  );
}

/// 度分秒必须使用非负分量，方向由半球单独表示，防止符号冲突。
CoordinateConversionResult dmsToDecimal({
  required String degreesInput,
  required String minutesInput,
  required String secondsInput,
  required CoordinateAxis axis,
  required String hemisphere,
}) {
  if (degreesInput.length > maxCoordinateInputLength ||
      minutesInput.length > maxCoordinateInputLength ||
      secondsInput.length > maxCoordinateInputLength) {
    return const CoordinateConversionResult(error: '坐标输入过长');
  }
  final degrees = double.tryParse(degreesInput.trim());
  final minutes = double.tryParse(minutesInput.trim());
  final seconds = double.tryParse(secondsInput.trim());
  if (degrees == null || minutes == null || seconds == null) {
    return const CoordinateConversionResult(error: '请输入有效的度、分、秒');
  }
  if (![degrees, minutes, seconds].every((value) => value.isFinite)) {
    return const CoordinateConversionResult(error: '坐标必须是有限数值');
  }
  if (degrees < 0 ||
      degrees > axis.limit ||
      minutes < 0 ||
      minutes >= 60 ||
      seconds < 0 ||
      seconds >= 60) {
    return CoordinateConversionResult(error: '${axis.label}范围无效；分和秒必须小于 60');
  }
  if (degrees == axis.limit && (minutes != 0 || seconds != 0)) {
    return CoordinateConversionResult(
      error: '${axis.label}达到 ${axis.limit.toInt()}° 时分和秒必须为 0',
    );
  }
  if (!axis.hemispheres.contains(hemisphere)) {
    return const CoordinateConversionResult(error: '方向与坐标类型不匹配');
  }
  var decimal = degrees + minutes / 60 + seconds / 3600;
  if (hemisphere == '南纬' || hemisphere == '西经') decimal = -decimal;
  return CoordinateConversionResult(
    decimal: decimal,
    dms:
        '$hemisphere ${_formatNumber(degrees)}° ${_formatNumber(minutes)}′ ${_formatNumber(seconds)}″',
  );
}

/// 使用 WGS84 平均地球半径进行球面近似；结果不应替代测绘或导航数据。
CoordinateDistanceResult calculateCoordinateDistance({
  required String startLatitude,
  required String startLongitude,
  required String endLatitude,
  required String endLongitude,
}) {
  final inputs = [
    _parseBoundedCoordinate(startLatitude, CoordinateAxis.latitude, '起点纬度'),
    _parseBoundedCoordinate(startLongitude, CoordinateAxis.longitude, '起点经度'),
    _parseBoundedCoordinate(endLatitude, CoordinateAxis.latitude, '终点纬度'),
    _parseBoundedCoordinate(endLongitude, CoordinateAxis.longitude, '终点经度'),
  ];
  for (final input in inputs) {
    if (input.error != null) {
      return CoordinateDistanceResult(error: input.error);
    }
  }
  final latitude1 = _radians(inputs[0].value!);
  final longitude1 = _radians(inputs[1].value!);
  final latitude2 = _radians(inputs[2].value!);
  final longitude2 = _radians(inputs[3].value!);
  final deltaLatitude = latitude2 - latitude1;
  final deltaLongitude = longitude2 - longitude1;
  final haversine =
      math.pow(math.sin(deltaLatitude / 2), 2) +
      math.cos(latitude1) *
          math.cos(latitude2) *
          math.pow(math.sin(deltaLongitude / 2), 2);
  final centralAngle = 2 * math.asin(math.sqrt(haversine.clamp(0, 1)));
  final distance = _earthMeanRadiusKm * centralAngle;
  if (distance < 1e-9) {
    return const CoordinateDistanceResult(distanceKm: 0, direction: '重合点');
  }
  final y = math.sin(deltaLongitude) * math.cos(latitude2);
  final x =
      math.cos(latitude1) * math.sin(latitude2) -
      math.sin(latitude1) * math.cos(latitude2) * math.cos(deltaLongitude);
  // 对跖点存在无限条等长大圆路径，不能伪造一个唯一初始方位。
  if (math.sqrt(x * x + y * y) < 1e-12) {
    return CoordinateDistanceResult(
      distanceKm: distance,
      direction: '对跖点方位不唯一',
    );
  }
  final bearing = (_degrees(math.atan2(y, x)) + 360) % 360;
  return CoordinateDistanceResult(
    distanceKm: distance,
    initialBearing: bearing,
    direction: _bearingDirection(bearing),
  );
}

({double? value, String? error}) _parseBoundedCoordinate(
  String input,
  CoordinateAxis axis,
  String label,
) {
  if (input.trim().isEmpty) return (value: null, error: '请输入$label');
  if (input.length > maxCoordinateInputLength) {
    return (value: null, error: '$label输入过长');
  }
  final value = double.tryParse(input.trim());
  if (value == null || !value.isFinite) {
    return (value: null, error: '$label必须是有效有限数值');
  }
  if (value < -axis.limit || value > axis.limit) {
    return (
      value: null,
      error: '$label必须在 -${axis.limit.toInt()} 到 ${axis.limit.toInt()} 之间',
    );
  }
  return (value: value, error: null);
}

String _bearingDirection(double bearing) {
  const labels = ['北', '东北', '东', '东南', '南', '西南', '西', '西北'];
  return labels[((bearing + 22.5) ~/ 45) % labels.length];
}

double _radians(double degrees) => degrees * math.pi / 180;
double _degrees(double radians) => radians * 180 / math.pi;

String _formatNumber(double value) =>
    value.toStringAsFixed(6).replaceFirst(RegExp(r'\.?0+$'), '');
