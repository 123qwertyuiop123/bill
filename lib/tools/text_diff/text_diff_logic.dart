enum DiffType { unchanged, added, removed }

class DiffLine {
  const DiffLine(this.type, this.text);

  final DiffType type;
  final String text;
}

/// 使用最长公共子序列进行逐行对比。
///
/// 为控制移动端内存，调用方输入最多取 200 行；算法不会处理无限文本。
List<DiffLine> diffLines(String original, String updated) {
  final left = original.isEmpty
      ? <String>[]
      : original.split('\n').take(200).toList();
  final right = updated.isEmpty
      ? <String>[]
      : updated.split('\n').take(200).toList();
  final table = List.generate(
    left.length + 1,
    (_) => List<int>.filled(right.length + 1, 0),
  );
  for (var i = left.length - 1; i >= 0; i--) {
    for (var j = right.length - 1; j >= 0; j--) {
      table[i][j] = left[i] == right[j]
          ? table[i + 1][j + 1] + 1
          : (table[i + 1][j] >= table[i][j + 1]
                ? table[i + 1][j]
                : table[i][j + 1]);
    }
  }
  final result = <DiffLine>[];
  var i = 0;
  var j = 0;
  while (i < left.length && j < right.length) {
    if (left[i] == right[j]) {
      result.add(DiffLine(DiffType.unchanged, left[i]));
      i++;
      j++;
    } else if (table[i + 1][j] >= table[i][j + 1]) {
      result.add(DiffLine(DiffType.removed, left[i++]));
    } else {
      result.add(DiffLine(DiffType.added, right[j++]));
    }
  }
  while (i < left.length) {
    result.add(DiffLine(DiffType.removed, left[i++]));
  }
  while (j < right.length) {
    result.add(DiffLine(DiffType.added, right[j++]));
  }
  return result;
}
