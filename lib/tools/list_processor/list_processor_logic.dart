import 'dart:math';

List<String> parseList(String input, {bool keepEmpty = false}) {
  if (input.length > 50000) return const [];
  final values = input
      .split(RegExp(r'[\n,，]+'))
      .map((item) => item.trim())
      .take(1000);
  return keepEmpty
      ? values.toList()
      : values.where((item) => item.isNotEmpty).toList();
}

List<String> sortList(List<String> items) =>
    List<String>.of(items)
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

List<String> uniqueList(List<String> items) {
  final seen = <String>{};
  return items.where((item) => seen.add(item)).toList();
}

List<String> shuffleList(List<String> items, {Random? random}) =>
    List<String>.of(items)..shuffle(random ?? Random.secure());
