import 'dart:convert';

import 'package:crypto/crypto.dart';

const maxHashInputLength = 100000;

enum HashAlgorithm { md5, sha1, sha256, sha512 }

extension HashAlgorithmLabel on HashAlgorithm {
  String get label => switch (this) {
    HashAlgorithm.md5 => 'MD5',
    HashAlgorithm.sha1 => 'SHA-1',
    HashAlgorithm.sha256 => 'SHA-256',
    HashAlgorithm.sha512 => 'SHA-512',
  };
}

class HashToolResult {
  const HashToolResult({this.digest = '', this.error});

  final String digest;
  final String? error;
  bool get isSuccess => error == null;
}

/// 对 UTF-8 文本生成单向摘要；摘要不能用于恢复原文，也不适合直接存储密码。
HashToolResult generateTextHash(String input, HashAlgorithm algorithm) {
  if (input.isEmpty) return const HashToolResult(error: '请输入文本');
  if (input.length > maxHashInputLength) {
    return const HashToolResult(error: '文本不能超过 100000 个字符');
  }
  final bytes = utf8.encode(input);
  final digest = switch (algorithm) {
    HashAlgorithm.md5 => md5.convert(bytes),
    HashAlgorithm.sha1 => sha1.convert(bytes),
    HashAlgorithm.sha256 => sha256.convert(bytes),
    HashAlgorithm.sha512 => sha512.convert(bytes),
  };
  return HashToolResult(digest: digest.toString());
}
