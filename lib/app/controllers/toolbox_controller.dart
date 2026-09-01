import 'package:flutter/foundation.dart';

import '../models/tool_definition.dart';
import '../services/tool_preferences_service.dart';

/// 管理工具箱的收藏、最近使用和筛选状态。
class ToolboxController extends ChangeNotifier {
  ToolboxController({
    required this.tools,
    ToolPreferencesService? preferencesService,
  }) : _preferencesService = preferencesService ?? ToolPreferencesService();

  final List<ToolDefinition> tools;
  final ToolPreferencesService _preferencesService;

  bool loading = true;
  bool _disposed = false;
  Set<String> _favoriteIds = <String>{};
  List<String> _recentIds = <String>[];

  Set<String> get favoriteIds => Set.unmodifiable(_favoriteIds);
  List<String> get recentIds => List.unmodifiable(_recentIds);

  List<ToolDefinition> get favorites =>
      tools.where((tool) => _favoriteIds.contains(tool.id)).toList();

  List<ToolDefinition> get recents => _recentIds
      .map(findById)
      .whereType<ToolDefinition>()
      .toList(growable: false);

  Future<void> initialize() async {
    final snapshot = await _preferencesService.load();
    if (_disposed) return;
    final validIds = tools.map((tool) => tool.id).toSet();
    _favoriteIds = snapshot.favoriteIds.intersection(validIds);
    _recentIds = snapshot.recentIds.where(validIds.contains).toList();
    loading = false;
    notifyListeners();
  }

  ToolDefinition? findById(String id) {
    for (final tool in tools) {
      if (tool.id == id) return tool;
    }
    return null;
  }

  bool isFavorite(String id) => _favoriteIds.contains(id);

  Future<void> toggleFavorite(String id) async {
    if (findById(id) == null) return;
    if (!_favoriteIds.add(id)) _favoriteIds.remove(id);
    notifyListeners();
    await _save();
  }

  Future<void> markUsed(String id) async {
    if (findById(id) == null) return;
    _recentIds
      ..remove(id)
      ..insert(0, id);
    if (_recentIds.length > 8) _recentIds.removeRange(8, _recentIds.length);
    notifyListeners();
    await _save();
  }

  Future<void> clearRecents() async {
    _recentIds.clear();
    notifyListeners();
    await _save();
  }

  Future<void> _save() async {
    try {
      await _preferencesService.save(
        ToolPreferencesSnapshot(
          favoriteIds: _favoriteIds,
          recentIds: _recentIds,
        ),
      );
    } on Object {
      // 偏好保存失败不能阻止用户打开工具；下次启动使用上次成功的快照。
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
