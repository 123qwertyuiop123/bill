const maxMarkdownLength = 50000;

enum MarkdownBlockType { heading, paragraph, bullet, code }

class MarkdownBlock {
  const MarkdownBlock(this.type, this.text, {this.level = 0});

  final MarkdownBlockType type;
  final String text;
  final int level;
}

class MarkdownPreviewResult {
  const MarkdownPreviewResult({this.blocks = const [], this.error});

  final List<MarkdownBlock> blocks;
  final String? error;
  bool get isSuccess => error == null;
}

/// 解析安全、有限的 Markdown 子集。
///
/// 这里不会生成 HTML，也不会识别可点击链接或远程图片，因此用户输入无法触发
/// 脚本、网络请求或外部应用跳转。
MarkdownPreviewResult parseMarkdownPreview(String input) {
  if (input.trim().isEmpty) {
    return const MarkdownPreviewResult(error: '请输入 Markdown 内容');
  }
  if (input.length > maxMarkdownLength) {
    return const MarkdownPreviewResult(error: 'Markdown 内容不能超过 50000 个字符');
  }

  final blocks = <MarkdownBlock>[];
  final codeLines = <String>[];
  var inCodeBlock = false;
  for (final line in input.replaceAll('\r\n', '\n').split('\n')) {
    if (line.trimLeft().startsWith('```')) {
      if (inCodeBlock) {
        blocks.add(MarkdownBlock(MarkdownBlockType.code, codeLines.join('\n')));
        codeLines.clear();
      }
      inCodeBlock = !inCodeBlock;
      continue;
    }
    if (inCodeBlock) {
      codeLines.add(line);
      continue;
    }
    if (line.trim().isEmpty) continue;

    final heading = RegExp(r'^(#{1,3})\s+(.+)$').firstMatch(line);
    if (heading != null) {
      blocks.add(
        MarkdownBlock(
          MarkdownBlockType.heading,
          heading.group(2)!,
          level: heading.group(1)!.length,
        ),
      );
      continue;
    }
    final bullet = RegExp(r'^\s*[-*]\s+(.+)$').firstMatch(line);
    if (bullet != null) {
      blocks.add(MarkdownBlock(MarkdownBlockType.bullet, bullet.group(1)!));
      continue;
    }
    blocks.add(MarkdownBlock(MarkdownBlockType.paragraph, line));
  }
  if (inCodeBlock) {
    return const MarkdownPreviewResult(error: '代码块缺少结束标记 ```');
  }
  return MarkdownPreviewResult(blocks: List.unmodifiable(blocks));
}

/// 将成对的 ** 标记拆成普通片段和粗体片段；不解释其他内联语法。
List<({String text, bool bold})> parseBoldSegments(String input) {
  final result = <({String text, bool bold})>[];
  var cursor = 0;
  var bold = false;
  while (cursor < input.length) {
    final marker = input.indexOf('**', cursor);
    if (marker < 0) {
      result.add((text: input.substring(cursor), bold: bold));
      break;
    }
    if (marker > cursor) {
      result.add((text: input.substring(cursor, marker), bold: bold));
    }
    bold = !bold;
    cursor = marker + 2;
  }
  if (result.isEmpty) result.add((text: input, bold: false));
  return result;
}
