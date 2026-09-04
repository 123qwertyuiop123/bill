import 'dart:convert';

const maxCsvJsonInputLength = 100000;
const maxCsvJsonOutputLength = 200000;
const maxCsvRows = 2000;
const maxCsvColumns = 100;

enum CsvJsonMode { csvToJson, jsonToCsv }

class CsvJsonResult {
  const CsvJsonResult({this.output = '', this.error});

  final String output;
  final String? error;
  bool get isSuccess => error == null;
}

CsvJsonResult convertCsvJson(String input, CsvJsonMode mode) {
  if (input.trim().isEmpty) return const CsvJsonResult(error: '请输入内容');
  if (input.length > maxCsvJsonInputLength) {
    return const CsvJsonResult(error: '输入不能超过 100000 个字符');
  }
  try {
    final output = switch (mode) {
      CsvJsonMode.csvToJson => _csvToJson(input),
      CsvJsonMode.jsonToCsv => _jsonToCsv(input),
    };
    if (output.length > maxCsvJsonOutputLength) {
      return const CsvJsonResult(error: '转换结果过大，请减少数据量');
    }
    return CsvJsonResult(output: output);
  } on FormatException catch (error) {
    return CsvJsonResult(error: error.message);
  }
}

String _csvToJson(String input) {
  final rows = _parseCsv(input);
  if (rows.length < 2) throw const FormatException('CSV 至少需要表头和一行数据');
  final headers = rows.first;
  if (headers.length > maxCsvColumns) {
    throw const FormatException('CSV 不能超过 100 列');
  }
  if (headers.any((header) => header.trim().isEmpty)) {
    throw const FormatException('CSV 表头不能为空');
  }
  if (headers.toSet().length != headers.length) {
    throw const FormatException('CSV 表头不能重复');
  }

  final objects = <Map<String, String>>[];
  for (final row in rows.skip(1)) {
    if (row.length != headers.length) {
      throw const FormatException('CSV 每行列数必须与表头一致');
    }
    objects.add({
      for (var index = 0; index < headers.length; index++)
        headers[index]: row[index],
    });
  }
  return const JsonEncoder.withIndent('  ').convert(objects);
}

String _jsonToCsv(String input) {
  final Object? decoded;
  try {
    decoded = jsonDecode(input);
  } on FormatException {
    // SDK 原始解析错误为英文且可能包含输入片段，只返回可处理的中文提示。
    throw const FormatException('JSON 格式无效，请检查括号、引号和逗号');
  }
  if (decoded is! List || decoded.isEmpty) {
    throw const FormatException('JSON 必须是非空对象数组');
  }
  if (decoded.length > maxCsvRows) {
    throw const FormatException('JSON 不能超过 2000 行');
  }
  final rows = <Map<String, Object?>>[];
  final headers = <String>[];
  for (final item in decoded) {
    if (item is! Map<String, dynamic>) {
      throw const FormatException('JSON 数组中的每一项都必须是对象');
    }
    final row = Map<String, Object?>.from(item);
    for (final entry in row.entries) {
      if (entry.value is List || entry.value is Map) {
        throw const FormatException('暂不支持嵌套数组或对象');
      }
      if (!headers.contains(entry.key)) headers.add(entry.key);
    }
    rows.add(row);
  }
  if (headers.isEmpty) throw const FormatException('JSON 对象不能全部为空');
  if (headers.length > maxCsvColumns) {
    throw const FormatException('JSON 不能超过 100 列');
  }

  final buffer = StringBuffer(headers.map(_escapeCsvField).join(','));
  for (final row in rows) {
    buffer
      ..writeln()
      ..write(
        headers
            .map((header) => _escapeCsvField(_scalarText(row[header])))
            .join(','),
      );
  }
  return buffer.toString();
}

String _scalarText(Object? value) => value == null ? '' : value.toString();

String _escapeCsvField(String value) {
  if (!value.contains(RegExp('[,"\r\n]'))) return value;
  return '"${value.replaceAll('"', '""')}"';
}

/// 按 RFC 4180 常用规则解析字段；解析器不执行公式或把内容当作文件路径。
List<List<String>> _parseCsv(String input) {
  final rows = <List<String>>[];
  var row = <String>[];
  final field = StringBuffer();
  var inQuotes = false;
  var quoteClosed = false;

  void commitField() {
    row.add(field.toString());
    field.clear();
    quoteClosed = false;
  }

  void commitRow() {
    commitField();
    if (!(row.length == 1 && row.first.isEmpty)) rows.add(row);
    row = <String>[];
    if (rows.length > maxCsvRows) {
      throw const FormatException('CSV 不能超过 2000 行');
    }
  }

  for (var index = 0; index < input.length; index++) {
    final character = input[index];
    if (inQuotes) {
      if (character == '"') {
        if (index + 1 < input.length && input[index + 1] == '"') {
          field.write('"');
          index++;
        } else {
          inQuotes = false;
          quoteClosed = true;
        }
      } else {
        field.write(character);
      }
      continue;
    }

    if (character == '"') {
      if (field.isNotEmpty || quoteClosed) {
        throw const FormatException('CSV 引号位置无效');
      }
      inQuotes = true;
    } else if (character == ',') {
      commitField();
    } else if (character == '\n' || character == '\r') {
      if (character == '\r' &&
          index + 1 < input.length &&
          input[index + 1] == '\n') {
        index++;
      }
      commitRow();
    } else {
      if (quoteClosed) throw const FormatException('CSV 引号后只能是逗号或换行');
      field.write(character);
    }
  }
  if (inQuotes) throw const FormatException('CSV 引号未闭合');
  if (field.isNotEmpty || row.isNotEmpty || quoteClosed) commitRow();
  if (rows.isEmpty) throw const FormatException('CSV 没有有效内容');
  return rows;
}
