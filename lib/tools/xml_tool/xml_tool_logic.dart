import 'dart:convert';

import 'package:xml/xml.dart';

const maxXmlInputBytes = 200 * 1024;
const maxXmlInputCharacters = 200 * 1024;
const maxXmlOutputBytes = 1024 * 1024;
const maxXmlNodes = 5000;
const maxXmlDepth = 64;

enum XmlToolMode { format, minify, validate }

class XmlToolResult {
  const XmlToolResult({this.output = '', this.error, this.elementCount = 0});

  final String output;
  final String? error;
  final int elementCount;
  bool get isSuccess => error == null;
}

/// 禁止文档类型和实体声明，确保工具不会形成 XXE 或实体膨胀入口。
XmlToolResult processXml(String input, XmlToolMode mode) {
  final source = input.trim();
  if (source.isEmpty) return const XmlToolResult(error: '请输入 XML 内容');
  if (source.length > maxXmlInputCharacters ||
      utf8.encode(source).length > maxXmlInputBytes) {
    return const XmlToolResult(error: 'XML 不能超过 200 KB');
  }
  if (RegExp(
    r'<!\s*(DOCTYPE|ENTITY)\b',
    caseSensitive: false,
  ).hasMatch(source)) {
    return const XmlToolResult(error: '为保证安全，不支持 DTD 或实体声明');
  }

  try {
    final document = XmlDocument.parse(source);
    final metrics = _measureXml(document);
    final output = switch (mode) {
      XmlToolMode.format => document.toXmlString(
        pretty: true,
        indent: '  ',
        newLine: '\n',
      ),
      // XML 的空白文本节点可能属于正文。没有 DTD 或 schema 时无法可靠区分
      // 排版缩进和业务内容，因此只关闭美化输出，不删除任何文本节点。
      XmlToolMode.minify => document.toXmlString(pretty: false),
      XmlToolMode.validate => 'XML 格式正确',
    };
    if (utf8.encode(output).length > maxXmlOutputBytes) {
      return const XmlToolResult(error: '处理结果超过 1 MB，已停止输出');
    }
    return XmlToolResult(output: output, elementCount: metrics.elementCount);
  } on _XmlLimitException catch (error) {
    return XmlToolResult(error: error.message);
  } on XmlParserException {
    return const XmlToolResult(error: 'XML 格式无效，请检查标签和属性');
  } on FormatException {
    return const XmlToolResult(error: 'XML 格式无效，请检查标签和属性');
  } catch (_) {
    return const XmlToolResult(error: 'XML 处理失败');
  }
}

_XmlMetrics _measureXml(XmlNode root) {
  var nodes = 0;
  var elements = 0;

  void visit(XmlNode node, int depth) {
    nodes++;
    if (nodes > maxXmlNodes) {
      throw const _XmlLimitException('XML 节点不能超过 5000 个');
    }
    if (depth > maxXmlDepth) {
      throw const _XmlLimitException('XML 嵌套不能超过 64 层');
    }
    if (node is XmlElement) elements++;
    for (final child in node.children) {
      visit(child, depth + 1);
    }
  }

  visit(root, 0);
  return _XmlMetrics(elementCount: elements);
}

class _XmlMetrics {
  const _XmlMetrics({required this.elementCount});
  final int elementCount;
}

class _XmlLimitException implements Exception {
  const _XmlLimitException(this.message);
  final String message;
}
