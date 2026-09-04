enum PlaceholderLanguage { chinese, latin }

/// 数量边界在逻辑层再次校验，避免绕过输入框限制分配大量字符串。
String generatePlaceholderText(
  int paragraphs,
  int sentences,
  PlaceholderLanguage language,
) {
  if (paragraphs < 1 || paragraphs > 20) {
    throw const FormatException('段落数量请输入 1–20 的整数');
  }
  if (sentences < 1 || sentences > 10) {
    throw const FormatException('每段句数请输入 1–10 的整数');
  }
  // 中文句库为项目自编素材；固定轮换用于排版，不宣称随机或 AI 生成。
  const chinese = [
    '清晨的阳光洒在窗边。',
    '新的一天从这里开始。',
    '简洁的页面便于阅读。',
    '适当留白让内容更清晰。',
    '这是用于排版的示例。',
    '实际内容可在之后替换。',
  ];
  const latin = [
    'Lorem ipsum dolor sit amet.',
    'Consectetur adipiscing elit.',
    'Sed do eiusmod tempor incididunt.',
    'Ut labore et dolore magna aliqua.',
  ];
  final source = language == PlaceholderLanguage.chinese ? chinese : latin;
  final output = List.generate(
    paragraphs,
    (p) => List.generate(
      sentences,
      (s) => source[(p * sentences + s) % source.length],
    ).join(language == PlaceholderLanguage.chinese ? '' : ' '),
  ).join('\n\n');
  if (output.length > 20000) {
    throw const FormatException('生成结果不能超过 20000 个字符');
  }
  return output;
}
