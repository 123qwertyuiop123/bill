import 'dart:math';

const minUuidBatchSize = 1;
const maxUuidBatchSize = 20;

enum UuidVersion { v4, v7 }

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

  return _formatUuidBytes(bytes);
}

/// 按 RFC 9562 生成 UUID v7：前 48 位为 Unix 毫秒，剩余位使用安全随机源。
///
/// 时间字段让标识符大体可排序，也会暴露生成时间，因此不能把 v7 当作密钥或令牌。
String generateUuidV7({DateTime? now}) {
  final milliseconds = (now ?? DateTime.now()).toUtc().millisecondsSinceEpoch;
  if (milliseconds < 0 || milliseconds > 0xffffffffffff) {
    throw RangeError('UUID v7 时间超出 48 位范围');
  }
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[0] = (milliseconds >> 40) & 0xff;
  bytes[1] = (milliseconds >> 32) & 0xff;
  bytes[2] = (milliseconds >> 24) & 0xff;
  bytes[3] = (milliseconds >> 16) & 0xff;
  bytes[4] = (milliseconds >> 8) & 0xff;
  bytes[5] = milliseconds & 0xff;
  bytes[6] = (bytes[6] & 0x0f) | 0x70;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;

  return _formatUuidBytes(bytes);
}

String _formatUuidBytes(List<int> bytes) {
  final hex = bytes
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
      '${hex.substring(20)}';
}

UuidBatchResult generateUuidBatch(
  int count, {
  UuidVersion version = UuidVersion.v4,
}) {
  if (count < minUuidBatchSize || count > maxUuidBatchSize) {
    return const UuidBatchResult(error: '单次只能生成 1 至 20 个 UUID');
  }
  try {
    return UuidBatchResult(
      values: List<String>.generate(
        count,
        (_) => version == UuidVersion.v4 ? generateUuidV4() : generateUuidV7(),
      ),
    );
  } on UnsupportedError {
    return const UuidBatchResult(error: '当前设备不支持安全随机源');
  } on RangeError {
    return const UuidBatchResult(error: '当前设备时间超出 UUID v7 支持范围');
  }
}
