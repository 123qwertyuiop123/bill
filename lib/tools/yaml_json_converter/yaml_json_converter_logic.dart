import 'dart:collection';
import 'dart:convert';

import 'package:yaml/yaml.dart';

const maxYamlJsonInputBytes = 200 * 1024;
const maxYamlJsonInputCharacters = 200 * 1024;
const maxYamlJsonOutputBytes = 1024 * 1024;
const maxYamlJsonNodes = 5000;
const maxYamlJsonDepth = 64;

enum YamlJsonMode { yamlToJson, jsonToYaml }

class YamlJsonResult {
  const YamlJsonResult({this.output = '', this.error});

  final String output;
  final String? error;
  bool get isSuccess => error == null;
}

/// 在解析前限制字节数，解析后再限制节点和深度，避免小文本制造过大的对象树。
YamlJsonResult convertYamlJson(String input, YamlJsonMode mode) {
  final source = input.trim();
  if (source.isEmpty) return const YamlJsonResult(error: '请输入需要转换的内容');
  if (source.length > maxYamlJsonInputCharacters ||
      utf8.encode(source).length > maxYamlJsonInputBytes) {
    return const YamlJsonResult(error: '输入内容不能超过 200 KB');
  }
  if (mode == YamlJsonMode.yamlToJson && _containsExplicitYamlTag(source)) {
    return const YamlJsonResult(error: '为保证数据安全，不支持 YAML 自定义标签');
  }

  try {
    final Object? value = switch (mode) {
      YamlJsonMode.yamlToJson => _convertYamlNode(
        loadYamlNode(source),
        0,
        _YamlConversionBudget(),
        HashSet<YamlNode>.identity(),
      ),
      YamlJsonMode.jsonToYaml => jsonDecode(source),
    };
    _validateTree(value);
    final output = switch (mode) {
      YamlJsonMode.yamlToJson => const JsonEncoder.withIndent(
        '  ',
      ).convert(value),
      YamlJsonMode.jsonToYaml => _writeYaml(value, 0),
    };
    if (utf8.encode(output).length > maxYamlJsonOutputBytes) {
      return const YamlJsonResult(error: '转换结果超过 1 MB，已停止输出');
    }
    return YamlJsonResult(output: output);
  } on FormatException {
    return YamlJsonResult(
      error: mode == YamlJsonMode.yamlToJson
          ? 'YAML 格式无效或包含不支持的结构'
          : 'JSON 格式无效',
    );
  } on _TreeLimitException catch (error) {
    return YamlJsonResult(error: error.message);
  } catch (_) {
    // 不把解析器内部异常、输入片段或堆栈直接展示给用户。
    return const YamlJsonResult(error: '转换失败，请检查数据结构');
  }
}

bool _containsExplicitYamlTag(String source) {
  var singleQuoted = false;
  var doubleQuoted = false;
  var comment = false;
  var escaped = false;
  for (var index = 0; index < source.length; index++) {
    final character = source[index];
    if (comment) {
      if (character == '\n') comment = false;
      continue;
    }
    if (doubleQuoted) {
      if (escaped) {
        escaped = false;
      } else if (character == '\\') {
        escaped = true;
      } else if (character == '"') {
        doubleQuoted = false;
      }
      continue;
    }
    if (singleQuoted) {
      if (character == "'" &&
          index + 1 < source.length &&
          source[index + 1] == "'") {
        index++;
      } else if (character == "'") {
        singleQuoted = false;
      }
      continue;
    }
    if (character == '"') {
      doubleQuoted = true;
      continue;
    }
    if (character == "'") {
      singleQuoted = true;
      continue;
    }
    final previous = index == 0 ? '\n' : source[index - 1];
    if (character == '#' && RegExp(r'[\s\[\]{},]').hasMatch(previous)) {
      comment = true;
      continue;
    }
    if (character == '!' && RegExp(r'[\s\[\]{},:?-]').hasMatch(previous)) {
      return true;
    }
  }
  return false;
}

Object? _convertYamlNode(
  YamlNode node,
  int depth,
  _YamlConversionBudget budget,
  Set<YamlNode> activeNodes,
) {
  budget.consume(depth);
  if (node is YamlScalar) {
    final value = node.value;
    if (value == null || value is String || value is num || value is bool) {
      return value;
    }
    throw const FormatException('Unsupported YAML scalar');
  }
  if (!activeNodes.add(node)) {
    throw const FormatException('Recursive YAML aliases are unsupported');
  }
  try {
    if (node is YamlList) {
      return [
        for (final child in node.nodes)
          _convertYamlNode(child, depth + 1, budget, activeNodes),
      ];
    }
    if (node is YamlMap) {
      final result = <String, Object?>{};
      for (final entry in node.nodes.entries) {
        final key = _convertYamlNode(entry.key, depth + 1, budget, activeNodes);
        if (key is! String) {
          throw const FormatException('YAML keys must be strings');
        }
        result[key] = _convertYamlNode(
          entry.value,
          depth + 1,
          budget,
          activeNodes,
        );
      }
      return result;
    }
    throw const FormatException('Unsupported YAML node');
  } finally {
    activeNodes.remove(node);
  }
}

void _validateTree(Object? root) {
  var nodes = 0;

  void visit(Object? value, int depth) {
    nodes++;
    if (nodes > maxYamlJsonNodes) {
      throw const _TreeLimitException('数据节点不能超过 5000 个');
    }
    if (depth > maxYamlJsonDepth) {
      throw const _TreeLimitException('嵌套不能超过 64 层');
    }
    if (value == null || value is String || value is bool) return;
    if (value is num) {
      if (!value.isFinite) throw const FormatException('Non-finite number');
      return;
    }
    if (value is List) {
      for (final item in value) {
        visit(item, depth + 1);
      }
      return;
    }
    if (value is Map) {
      for (final entry in value.entries) {
        if (entry.key is! String) {
          throw const FormatException('Keys must be strings');
        }
        visit(entry.value, depth + 1);
      }
      return;
    }
    throw const FormatException('Unsupported value');
  }

  visit(root, 0);
}

String _writeYaml(Object? value, int indent) {
  final padding = ' ' * indent;
  if (value is Map) {
    if (value.isEmpty) return '$padding{}';
    return value.entries
        .map((entry) {
          final key = _yamlKey(entry.key as String);
          final child = entry.value;
          return _isScalar(child)
              ? '$padding$key: ${_yamlScalar(child)}'
              : '$padding$key:\n${_writeYaml(child, indent + 2)}';
        })
        .join('\n');
  }
  if (value is List) {
    if (value.isEmpty) return '$padding[]';
    return value
        .map((child) {
          return _isScalar(child)
              ? '$padding- ${_yamlScalar(child)}'
              : '$padding-\n${_writeYaml(child, indent + 2)}';
        })
        .join('\n');
  }
  return '$padding${_yamlScalar(value)}';
}

bool _isScalar(Object? value) =>
    value == null || value is String || value is num || value is bool;

String _yamlKey(String value) =>
    RegExp(r'^[A-Za-z_][A-Za-z0-9_-]*$').hasMatch(value)
    ? value
    : jsonEncode(value);

String _yamlScalar(Object? value) {
  if (value == null) return 'null';
  if (value is bool || value is num) return value.toString();
  // JSON 字符串也是合法 YAML 标量，可稳定处理冒号、换行和保留字。
  return jsonEncode(value);
}

class _TreeLimitException implements Exception {
  const _TreeLimitException(this.message);
  final String message;
}

class _YamlConversionBudget {
  var nodes = 0;

  void consume(int depth) {
    nodes++;
    if (nodes > maxYamlJsonNodes) {
      throw const _TreeLimitException('数据节点不能超过 5000 个');
    }
    if (depth > maxYamlJsonDepth) {
      throw const _TreeLimitException('嵌套不能超过 64 层');
    }
  }
}
