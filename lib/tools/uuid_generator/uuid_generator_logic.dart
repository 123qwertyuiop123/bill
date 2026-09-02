import 'dart:math';

const minUuidBatchSize = 1;
const maxUuidBatchSize = 20;

class UuidBatchResult {
  const UuidBatchResult({this.values = const [], this.error});

  final List<String> values;
  final String? error;
  bool get isSuccess => error == null;
}

/// UUID v4 必须使用系统安全随机源；不得退回到可预测的伪随机种子。
String generateUuidV4() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;

  final hex = bytes
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
      '${hex.substring(20)}';
}

UuidBatchResult generateUuidBatch(int count) {
  if (count < minUuidBatchSize || count > maxUuidBatchSize) {
    return const UuidBatchResult(error: '单次只能生成 1 至 20 个 UUID');
  }
  try {
    return UuidBatchResult(
      values: List<String>.generate(count, (_) => generateUuidV4()),
    );
  } on UnsupportedError {
    return const UuidBatchResult(error: '当前设备不支持安全随机源');
  }
}
