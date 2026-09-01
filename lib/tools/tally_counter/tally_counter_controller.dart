import 'package:flutter/foundation.dart';

import 'tally_counter_model.dart';
import 'tally_counter_service.dart';

class TallyCounterController extends ChangeNotifier {
  TallyCounterController({TallyCounterService? service})
    : _service = service ?? TallyCounterService();

  final TallyCounterService _service;
  List<TallyCounter> counters = const [];
  String? selectedId;
  bool loading = true;
  bool _disposed = false;

  TallyCounter? get selected {
    for (final item in counters) {
      if (item.id == selectedId) return item;
    }
    return counters.isEmpty ? null : counters.first;
  }

  Future<void> initialize() async {
    final loaded = await _service.load();
    if (_disposed) return;
    counters = loaded.isEmpty
        ? const [
            TallyCounter(id: 'water', name: '喝水', value: 5),
            TallyCounter(id: 'exercise', name: '俯卧撑', value: 32),
            TallyCounter(id: 'stock', name: '库存', value: 126),
          ]
        : loaded;
    selectedId = counters.first.id;
    loading = false;
    notifyListeners();
    if (loaded.isEmpty) await _save();
  }

  void select(String id) {
    if (!counters.any((item) => item.id == id)) return;
    selectedId = id;
    notifyListeners();
  }

  Future<void> change(int delta) async {
    final item = selected;
    if (item == null) return;
    final next = (item.value + delta).clamp(-999999999, 999999999);
    _replace(item.copyWith(value: next));
    await _save();
  }

  Future<void> reset() async {
    final item = selected;
    if (item == null) return;
    _replace(item.copyWith(value: 0));
    await _save();
  }

  Future<bool> add(String name) async {
    final safeName = name.trim();
    if (safeName.isEmpty || safeName.length > 30 || counters.length >= 100) {
      return false;
    }
    final id = 'counter_${DateTime.now().microsecondsSinceEpoch}';
    counters = [...counters, TallyCounter(id: id, name: safeName, value: 0)];
    selectedId = id;
    notifyListeners();
    await _save();
    return true;
  }

  void _replace(TallyCounter next) {
    counters = [
      for (final item in counters)
        if (item.id == next.id) next else item,
    ];
    notifyListeners();
  }

  Future<void> _save() async {
    try {
      await _service.save(counters);
    } on Object {
      // 本地保存失败不回滚当前计数，避免按钮失去响应。
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
