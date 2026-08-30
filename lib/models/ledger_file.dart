enum LedgerLineFormat {
  day,
  fullDate;

  String get label => switch (this) {
    day => '日期开头',
    fullDate => '完整日期开头',
  };

  static LedgerLineFormat parse(Object? value) =>
      value == LedgerLineFormat.fullDate.name
      ? LedgerLineFormat.fullDate
      : LedgerLineFormat.day;
}

class LedgerFile {
  const LedgerFile({
    required this.id,
    required this.fileName,
    this.lineFormat = LedgerLineFormat.day,
  });

  static const defaultId = 'default';

  final String id;
  final String fileName;
  final LedgerLineFormat lineFormat;

  bool get isDefault => id == defaultId;

  LedgerFile copyWith({String? fileName, LedgerLineFormat? lineFormat}) =>
      LedgerFile(
        id: id,
        fileName: fileName ?? this.fileName,
        lineFormat: lineFormat ?? this.lineFormat,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'fileName': fileName,
    'lineFormat': lineFormat.name,
  };

  static LedgerFile? tryFromJson(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    final id = value['id'];
    final fileName = value['fileName'];
    if (id is! String ||
        id.isEmpty ||
        id.length > 64 ||
        fileName is! String ||
        fileName.isEmpty ||
        fileName.length > 64) {
      return null;
    }
    return LedgerFile(
      id: id,
      fileName: fileName,
      lineFormat: LedgerLineFormat.parse(value['lineFormat']),
    );
  }
}
