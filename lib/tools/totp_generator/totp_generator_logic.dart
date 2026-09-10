import 'dart:typed_data';

import 'package:crypto/crypto.dart';

const maxTotpSecretLength = 256;

enum TotpAlgorithm { sha1, sha256, sha512 }

extension TotpAlgorithmLabel on TotpAlgorithm {
  String get label => switch (this) {
    TotpAlgorithm.sha1 => 'SHA-1',
    TotpAlgorithm.sha256 => 'SHA-256',
    TotpAlgorithm.sha512 => 'SHA-512',
  };
}

class TotpResult {
  const TotpResult({required this.code, required this.remainingSeconds});

  final String code;
  final int remainingSeconds;
}

/// 根据 RFC 6238 计算一次性验证码。
///
/// 密钥只在当前调用的内存中解码，不保存、不记录日志，也不会自动复制。
TotpResult generateTotp({
  required String secret,
  required int timestampSeconds,
  TotpAlgorithm algorithm = TotpAlgorithm.sha1,
  int digits = 6,
  int period = 30,
}) {
  if (timestampSeconds < 0) {
    throw const FormatException('设备时间无效');
  }
  if (digits != 6 && digits != 8) {
    throw const FormatException('验证码位数只支持 6 位或 8 位');
  }
  if (period != 30 && period != 60) {
    throw const FormatException('更新周期只支持 30 秒或 60 秒');
  }

  final key = decodeBase32Secret(secret);
  final counter = timestampSeconds ~/ period;
  final message = Uint8List(8);
  var value = counter;
  for (var index = 7; index >= 0; index--) {
    message[index] = value & 0xff;
    value >>= 8;
  }

  final hash = switch (algorithm) {
    TotpAlgorithm.sha1 => sha1,
    TotpAlgorithm.sha256 => sha256,
    TotpAlgorithm.sha512 => sha512,
  };
  final digest = Hmac(hash, key).convert(message).bytes;
  final offset = digest.last & 0x0f;
  final binary =
      ((digest[offset] & 0x7f) << 24) |
      ((digest[offset + 1] & 0xff) << 16) |
      ((digest[offset + 2] & 0xff) << 8) |
      (digest[offset + 3] & 0xff);
  final divisor = digits == 6 ? 1000000 : 100000000;
  final code = (binary % divisor).toString().padLeft(digits, '0');
  final remaining = period - (timestampSeconds % period);
  return TotpResult(code: code, remainingSeconds: remaining);
}

/// 严格解析常见的无填充或尾部带填充 Base32 密钥。
Uint8List decodeBase32Secret(String input) {
  final secret = input.trim().toUpperCase();
  if (secret.isEmpty) throw const FormatException('请输入 Base32 密钥');
  if (secret.length > maxTotpSecretLength) {
    throw const FormatException('密钥不能超过 256 个字符');
  }
  if (!RegExp(r'^[A-Z2-7]+=*$').hasMatch(secret)) {
    throw const FormatException('密钥只能包含 A–Z、2–7 和末尾填充符 =');
  }

  final paddingIndex = secret.indexOf('=');
  final body = paddingIndex < 0 ? secret : secret.substring(0, paddingIndex);
  if (body.isEmpty) throw const FormatException('Base32 密钥无有效内容');
  final remainder = body.length % 8;
  final expectedPadding = switch (remainder) {
    0 => 0,
    2 => 6,
    4 => 4,
    5 => 3,
    7 => 1,
    _ => -1,
  };
  final paddingLength = paddingIndex < 0 ? 0 : secret.length - paddingIndex;
  // RFC 4648 只允许能够组成完整字节的正文长度；出现填充时数量也必须精确匹配。
  if (expectedPadding < 0 ||
      (paddingIndex >= 0 &&
          (expectedPadding == 0 ||
              paddingLength != expectedPadding ||
              secret.length % 8 != 0))) {
    throw const FormatException('Base32 填充格式不正确');
  }

  var buffer = 0;
  var bitCount = 0;
  final output = BytesBuilder(copy: false);
  for (final codeUnit in body.codeUnits) {
    final value = codeUnit >= 65 && codeUnit <= 90
        ? codeUnit - 65
        : codeUnit - 50 + 26;
    buffer = (buffer << 5) | value;
    bitCount += 5;
    if (bitCount >= 8) {
      bitCount -= 8;
      output.addByte((buffer >> bitCount) & 0xff);
      buffer &= (1 << bitCount) - 1;
    }
  }
  // 非零的残留位不是规范 Base32，拒绝而不是静默丢弃。
  if (bitCount > 0 && buffer != 0) {
    throw const FormatException('Base32 密钥末尾包含无效位');
  }
  final bytes = output.takeBytes();
  if (bytes.isEmpty) throw const FormatException('Base32 密钥过短');
  return bytes;
}
