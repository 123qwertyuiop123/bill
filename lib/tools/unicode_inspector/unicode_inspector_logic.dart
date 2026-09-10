import 'dart:convert';

const maxUnicodeScalars = 256;
const maxUnicodeInputCharacters = 1024;

enum UnicodeFilter { all, asciiOnly }

class UnicodeEntry {
  const UnicodeEntry({
    required this.character,
    required this.displayCharacter,
    required this.codePoint,
    required this.utf8Hex,
    required this.utf16Hex,
    required this.dartEscape,
    required this.jsonEscape,
  });

  final String character;
  final String displayCharacter;
  final String codePoint;
  final String utf8Hex;
  final String utf16Hex;
  final String dartEscape;
  final String jsonEscape;
}

class UnicodeInspectionResult {
  const UnicodeInspectionResult({this.entries = const [], this.error});

  final List<UnicodeEntry> entries;
  final String? error;
  bool get isSuccess => error == null;

  String get copyText => entries
      .map(
        (entry) =>
            '${entry.displayCharacter}\t${entry.codePoint}\tUTF-8 ${entry.utf8Hex}\tUTF-16 ${entry.utf16Hex}',
      )
      .join('\n');
}

/// 按 Unicode 标量而不是 UTF-16 代码单元拆分，避免把表情拆成两个无效字符。
UnicodeInspectionResult inspectUnicode(
  String input, {
  UnicodeFilter filter = UnicodeFilter.all,
}) {
  if (input.isEmpty) return const UnicodeInspectionResult(error: '请输入需要检查的字符');
  if (input.length > maxUnicodeInputCharacters) {
    return const UnicodeInspectionResult(error: '输入内容过长，最多检查 256 个字符');
  }
  final runes = input.runes.toList(growable: false);
  if (runes.length > maxUnicodeScalars) {
    return const UnicodeInspectionResult(error: '最多检查 256 个 Unicode 字符');
  }

  final entries = <UnicodeEntry>[];
  for (final rune in runes) {
    if (filter == UnicodeFilter.asciiOnly && rune > 0x7f) continue;
    final character = String.fromCharCode(rune);
    final units = character.codeUnits;
    entries.add(
      UnicodeEntry(
        character: character,
        displayCharacter: _displayCharacter(rune, character),
        codePoint: 'U+${_hex(rune, 4)}',
        utf8Hex: utf8.encode(character).map((byte) => _hex(byte, 2)).join(' '),
        utf16Hex: units.map((unit) => _hex(unit, 4)).join(' '),
        dartEscape: '\\u{${rune.toRadixString(16).toUpperCase()}}',
        jsonEscape: units.map((unit) => '\\u${_hex(unit, 4)}').join(),
      ),
    );
  }
  return UnicodeInspectionResult(entries: entries);
}

String _displayCharacter(int rune, String character) => switch (rune) {
  0x20 => '空格',
  0x09 => '制表符',
  0x0a => '换行',
  0x0d => '回车',
  _ when rune < 0x20 || rune == 0x7f => '控制字符',
  _ => character,
};

String _hex(int value, int width) =>
    value.toRadixString(16).toUpperCase().padLeft(width, '0');
