import 'dart:math' as math;

enum MatrixOperation { determinant, transpose, inverse }

extension MatrixOperationLabel on MatrixOperation {
  String get label => switch (this) {
    MatrixOperation.determinant => '行列式',
    MatrixOperation.transpose => '转置',
    MatrixOperation.inverse => '逆矩阵',
  };
}

class MatrixResult {
  const MatrixResult({this.determinant, this.matrix});
  final double? determinant;
  final List<List<double>>? matrix;
}

/// 只接受固定的 2/3 阶矩阵；不解析表达式，不执行用户代码。
MatrixResult calculateMatrix(
  List<List<String>> input,
  MatrixOperation operation,
) {
  final n = input.length;
  if ((n != 2 && n != 3) || input.any((row) => row.length != n)) {
    throw const FormatException('仅支持 2×2 或 3×3 方阵');
  }
  final matrix = input
      .map(
        (row) => row.map((text) {
          final value = text.length <= 32 ? double.tryParse(text.trim()) : null;
          if (value == null || !value.isFinite || value.abs() > 1e12) {
            throw const FormatException('每项最多 32 字符，须为绝对值不超过 10¹² 的有限数字');
          }
          return value;
        }).toList(),
      )
      .toList();
  if (operation == MatrixOperation.transpose) {
    return MatrixResult(
      matrix: List.generate(n, (i) => List.generate(n, (j) => matrix[j][i])),
    );
  }
  final scale = matrix
      .expand((row) => row)
      .fold<double>(0, (s, x) => math.max(s, x.abs()));
  if (scale == 0) {
    if (operation == MatrixOperation.determinant) {
      return const MatrixResult(determinant: 0);
    }
    throw const FormatException('矩阵不可逆');
  }
  // 归一化与部分选主元限制中间数值；近奇异矩阵不输出误导性的逆矩阵。
  final work = List.generate(
    n,
    (i) => List.generate(
      2 * n,
      (j) => j < n ? matrix[i][j] / scale : (j - n == i ? 1.0 : 0.0),
    ),
  );
  for (var i = 0; i < n; i++) {
    for (var j = 0; j < n; j++) {
      if (matrix[i][j] != 0 && work[i][j] == 0) {
        throw const FormatException('元素数量级差异过大，无法可靠计算');
      }
    }
  }
  var determinant = 1.0;
  var nearSingular = false;
  for (var column = 0; column < n; column++) {
    var pivotRow = column;
    for (var row = column + 1; row < n; row++) {
      if (work[row][column].abs() > work[pivotRow][column].abs()) {
        pivotRow = row;
      }
    }
    final pivot = work[pivotRow][column];
    if (pivot == 0) {
      if (operation == MatrixOperation.determinant) {
        return const MatrixResult(determinant: 0);
      }
      throw const FormatException('矩阵不可逆');
    }
    if (pivot.abs() <= 1e-12) nearSingular = true;
    if (nearSingular && operation == MatrixOperation.inverse) {
      throw const FormatException('矩阵接近奇异，无法可靠计算逆矩阵');
    }
    if (pivotRow != column) {
      final row = work[column];
      work[column] = work[pivotRow];
      work[pivotRow] = row;
      determinant = -determinant;
    }
    // 行列式不构造逆矩阵，避免小主元除法造成无关的中间溢出。
    if (operation == MatrixOperation.determinant) {
      determinant *= pivot * scale;
      if (!determinant.isFinite || determinant == 0) {
        throw const FormatException('结果超出浮点数可表示范围');
      }
      for (var row = column + 1; row < n; row++) {
        final factor = work[row][column] / pivot;
        for (var j = column + 1; j < n; j++) {
          work[row][j] -= factor * work[column][j];
        }
        work[row][column] = 0;
      }
      continue;
    }
    for (var j = 0; j < 2 * n; j++) {
      work[column][j] /= pivot;
    }
    for (var row = 0; row < n; row++) {
      if (row == column) continue;
      final factor = work[row][column];
      for (var j = 0; j < 2 * n; j++) {
        work[row][j] -= factor * work[column][j];
      }
    }
  }
  if (operation == MatrixOperation.determinant) {
    return MatrixResult(determinant: determinant);
  }
  if (nearSingular) throw const FormatException('矩阵接近奇异，无法可靠计算逆矩阵');
  final inverse = List.generate(
    n,
    (i) => List.generate(n, (j) => work[i][j + n] / scale),
  );
  if (inverse.expand((row) => row).any((v) => !v.isFinite)) {
    throw const FormatException('逆矩阵超出浮点数可表示范围');
  }
  return MatrixResult(matrix: inverse);
}

String formatMatrixNumber(double value) {
  if (value == 0) return '0';
  if (value.abs() >= 1e12 || value.abs() < 1e-6) {
    return value.toStringAsExponential(8);
  }
  return value.toStringAsFixed(8).replaceFirst(RegExp(r'\.?0+$'), '');
}
