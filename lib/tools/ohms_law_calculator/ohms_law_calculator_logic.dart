import 'dart:math' as math;

const minElectricalValue = 1e-12;
const maxElectricalValue = 1e100;

enum ElectricalQuantity { voltage, current, resistance, power }

extension ElectricalQuantityLabel on ElectricalQuantity {
  String get label => switch (this) {
    ElectricalQuantity.voltage => '电压',
    ElectricalQuantity.current => '电流',
    ElectricalQuantity.resistance => '电阻',
    ElectricalQuantity.power => '功率',
  };

  String get symbol => switch (this) {
    ElectricalQuantity.voltage => 'V',
    ElectricalQuantity.current => 'A',
    ElectricalQuantity.resistance => 'Ω',
    ElectricalQuantity.power => 'W',
  };
}

class ElectricalUnit {
  const ElectricalUnit(this.label, this.factor);

  final String label;
  final double factor;
}

const _voltageUnits = <ElectricalUnit>[
  ElectricalUnit('µV', 1e-6),
  ElectricalUnit('mV', 1e-3),
  ElectricalUnit('V', 1),
  ElectricalUnit('kV', 1e3),
];
const _currentUnits = <ElectricalUnit>[
  ElectricalUnit('µA', 1e-6),
  ElectricalUnit('mA', 1e-3),
  ElectricalUnit('A', 1),
  ElectricalUnit('kA', 1e3),
];
const _resistanceUnits = <ElectricalUnit>[
  ElectricalUnit('mΩ', 1e-3),
  ElectricalUnit('Ω', 1),
  ElectricalUnit('kΩ', 1e3),
  ElectricalUnit('MΩ', 1e6),
];
const _powerUnits = <ElectricalUnit>[
  ElectricalUnit('µW', 1e-6),
  ElectricalUnit('mW', 1e-3),
  ElectricalUnit('W', 1),
  ElectricalUnit('kW', 1e3),
  ElectricalUnit('MW', 1e6),
];

List<ElectricalUnit> unitsFor(ElectricalQuantity quantity) =>
    switch (quantity) {
      ElectricalQuantity.voltage => _voltageUnits,
      ElectricalQuantity.current => _currentUnits,
      ElectricalQuantity.resistance => _resistanceUnits,
      ElectricalQuantity.power => _powerUnits,
    };

ElectricalUnit baseUnitFor(ElectricalQuantity quantity) =>
    unitsFor(quantity).firstWhere((unit) => unit.factor == 1);

enum OhmsKnownPair {
  voltageCurrent,
  voltageResistance,
  voltagePower,
  currentResistance,
  currentPower,
  resistancePower,
}

extension OhmsKnownPairInfo on OhmsKnownPair {
  (ElectricalQuantity, ElectricalQuantity) get quantities => switch (this) {
    OhmsKnownPair.voltageCurrent => (
      ElectricalQuantity.voltage,
      ElectricalQuantity.current,
    ),
    OhmsKnownPair.voltageResistance => (
      ElectricalQuantity.voltage,
      ElectricalQuantity.resistance,
    ),
    OhmsKnownPair.voltagePower => (
      ElectricalQuantity.voltage,
      ElectricalQuantity.power,
    ),
    OhmsKnownPair.currentResistance => (
      ElectricalQuantity.current,
      ElectricalQuantity.resistance,
    ),
    OhmsKnownPair.currentPower => (
      ElectricalQuantity.current,
      ElectricalQuantity.power,
    ),
    OhmsKnownPair.resistancePower => (
      ElectricalQuantity.resistance,
      ElectricalQuantity.power,
    ),
  };

  String get label {
    final (first, second) = quantities;
    return '${first.label} + ${second.label}';
  }

  String get formula => switch (this) {
    OhmsKnownPair.voltageCurrent => 'R = V ÷ I，P = V × I',
    OhmsKnownPair.voltageResistance => 'I = V ÷ R，P = V × I',
    OhmsKnownPair.voltagePower => 'I = P ÷ V，R = V² ÷ P',
    OhmsKnownPair.currentResistance => 'V = I × R，P = I² × R',
    OhmsKnownPair.currentPower => 'V = P ÷ I，R = P ÷ I²',
    OhmsKnownPair.resistancePower => 'I = √(P ÷ R)，V = √(P × R)',
  };
}

class OhmsLawResult {
  const OhmsLawResult({
    required this.voltage,
    required this.current,
    required this.resistance,
    required this.power,
  });

  final double voltage;
  final double current;
  final double resistance;
  final double power;

  double valueOf(ElectricalQuantity quantity) => switch (quantity) {
    ElectricalQuantity.voltage => voltage,
    ElectricalQuantity.current => current,
    ElectricalQuantity.resistance => resistance,
    ElectricalQuantity.power => power,
  };
}

/// 使用两个正数物理量计算欧姆定律的完整结果。
OhmsLawResult calculateOhmsLaw({
  required OhmsKnownPair pair,
  required double firstValue,
  required double secondValue,
}) {
  _validateValue(firstValue);
  _validateValue(secondValue);
  late final double voltage;
  late final double current;
  late final double resistance;
  late final double power;

  switch (pair) {
    case OhmsKnownPair.voltageCurrent:
      voltage = firstValue;
      current = secondValue;
      resistance = voltage / current;
      power = voltage * current;
    case OhmsKnownPair.voltageResistance:
      voltage = firstValue;
      resistance = secondValue;
      current = voltage / resistance;
      power = voltage * current;
    case OhmsKnownPair.voltagePower:
      voltage = firstValue;
      power = secondValue;
      current = power / voltage;
      resistance = voltage * voltage / power;
    case OhmsKnownPair.currentResistance:
      current = firstValue;
      resistance = secondValue;
      voltage = current * resistance;
      power = current * current * resistance;
    case OhmsKnownPair.currentPower:
      current = firstValue;
      power = secondValue;
      voltage = power / current;
      resistance = power / (current * current);
    case OhmsKnownPair.resistancePower:
      resistance = firstValue;
      power = secondValue;
      current = math.sqrt(power / resistance);
      voltage = math.sqrt(power * resistance);
  }

  for (final result in [voltage, current, resistance, power]) {
    if (!result.isFinite || result <= 0 || result > maxElectricalValue) {
      throw const FormatException('计算结果超出支持范围');
    }
  }
  return OhmsLawResult(
    voltage: voltage,
    current: current,
    resistance: resistance,
    power: power,
  );
}

void _validateValue(double value) {
  if (!value.isFinite ||
      value < minElectricalValue ||
      value > maxElectricalValue) {
    throw const FormatException('输入必须是支持范围内的大于 0 数值');
  }
}

/// 根据量级选择易读 SI 单位，不改变内部统一使用的基本单位。
String formatElectricalValue(ElectricalQuantity quantity, double value) {
  final units = unitsFor(quantity);
  var selected = units.first;
  for (final unit in units) {
    if (value >= unit.factor) selected = unit;
  }
  final scaled = value / selected.factor;
  return '${_formatNumber(scaled)} ${selected.label}';
}

String _formatNumber(double value) {
  final absolute = value.abs();
  if (absolute >= 1e9 || (absolute > 0 && absolute < 1e-3)) {
    return value.toStringAsExponential(4);
  }
  return value
      .toStringAsFixed(6)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}
