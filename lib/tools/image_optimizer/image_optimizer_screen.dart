import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/widgets/tool_result_widgets.dart';
import '../../app/widgets/tool_widgets.dart';
import '../../core/app_theme.dart';
import 'image_optimizer_logic.dart';
import 'services/image_optimizer_service.dart';

enum _ImageToolMode { optimize, privacy }

class ImageOptimizerScreen extends StatefulWidget {
  const ImageOptimizerScreen({
    super.key,
    this.service = const ImageOptimizerService(),
  });

  final ImageOptimizerService service;

  @override
  State<ImageOptimizerScreen> createState() => _ImageOptimizerScreenState();
}

class _ImageOptimizerScreenState extends State<ImageOptimizerScreen> {
  final _width = TextEditingController();
  final _height = TextEditingController();
  SelectedImageInfo? _selected;
  OptimizedImageInfo? _optimized;
  ImagePrivacyInfo? _privacy;
  _ImageToolMode _mode = _ImageToolMode.optimize;
  ImageOutputFormat _format = ImageOutputFormat.jpeg;
  bool _keepAspectRatio = true;
  bool _allowUpscale = false;
  double _quality = 80;
  bool _busy = false;
  String? _error;
  String? _savedPath;

  Future<void> _pick() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
      _optimized = null;
      _privacy = null;
      _savedPath = null;
    });
    try {
      final image = await widget.service.pickImage();
      if (!mounted || image == null) return;
      final scale = image.width > 1920 ? 1920 / image.width : 1.0;
      setState(() {
        _selected = image;
        _width.text = (image.width * scale).round().toString();
        _height.text = (image.height * scale).round().toString();
      });
    } on ImageOptimizerException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _optimize() async {
    final selected = _selected;
    if (_busy || selected == null) return;
    ImageTargetSize target;
    try {
      target = calculateImageTarget(
        widthText: _width.text,
        heightText: _height.text,
        sourceWidth: selected.width,
        sourceHeight: selected.height,
        keepAspectRatio: _keepAspectRatio,
        allowUpscale: _allowUpscale,
      );
    } on FormatException catch (error) {
      setState(() => _error = error.message);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _optimized = null;
      _savedPath = null;
    });
    try {
      final result = await widget.service.optimize(
        target: target,
        quality: _quality.round(),
        format: _format,
      );
      if (!mounted) return;
      setState(() => _optimized = result);
    } on ImageOptimizerException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _inspectMetadata() async {
    if (_busy || _selected == null) return;
    setState(() {
      _busy = true;
      _error = null;
      _privacy = null;
    });
    try {
      final result = await widget.service.inspectMetadata();
      if (mounted) setState(() => _privacy = result);
    } on ImageOptimizerException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    if (_busy || _optimized == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final path = await widget.service.save();
      if (!mounted) return;
      setState(() => _savedPath = path);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('图片已保存，可在文件管理器中查看')));
    } on ImageOptimizerException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _invalidateResult() {
    setState(() {
      _optimized = null;
      _savedPath = null;
      _error = null;
    });
  }

  @override
  void dispose() {
    _width.dispose();
    _height.dispose();
    super.dispose();
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }

  String _orientationLabel(String value) => switch (value) {
    'normal' => '正常',
    'rotate_90' => '旋转 90°',
    'rotate_180' => '旋转 180°',
    'rotate_270' => '旋转 270°',
    'flip_horizontal' => '水平翻转',
    'flip_vertical' => '垂直翻转',
    'transpose' => '转置',
    'transverse' => '横向转置',
    _ => '未记录',
  };

  @override
  Widget build(BuildContext context) => ToolPageScaffold(
    title: '图片优化',
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SegmentedButton<_ImageToolMode>(
            segments: const [
              ButtonSegment(
                value: _ImageToolMode.optimize,
                icon: Icon(Icons.auto_fix_high_outlined),
                label: Text('图片优化'),
              ),
              ButtonSegment(
                value: _ImageToolMode.privacy,
                icon: Icon(Icons.privacy_tip_outlined),
                label: Text('隐私检查'),
              ),
            ],
            selected: {_mode},
            showSelectedIcon: false,
            onSelectionChanged: _busy
                ? null
                : (selection) => setState(() {
                    _mode = selection.first;
                    _error = null;
                  }),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _mode == _ImageToolMode.optimize ? '离线压缩、缩放与格式转换' : '离线检查可能泄露隐私的图片信息',
        ),
        const SizedBox(height: 16),
        Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            leading: const Icon(Icons.image_outlined),
            title: Text(
              _selected?.name ?? '尚未选择图片',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: _selected == null
                ? const Text('支持 JPEG、PNG、WebP')
                : Text(
                    '${_selected!.width} × ${_selected!.height} · ${_formatBytes(_selected!.size)}',
                  ),
            trailing: OutlinedButton(
              key: const Key('pickImage'),
              onPressed: _busy ? null : _pick,
              child: const Text('选择图片'),
            ),
          ),
        ),
        if (_mode == _ImageToolMode.optimize) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _sizeField(_width, '目标宽度')),
              const SizedBox(width: 12),
              Expanded(child: _sizeField(_height, '目标高度')),
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('保持宽高比'),
            value: _keepAspectRatio,
            onChanged: _selected == null
                ? null
                : (value) {
                    _keepAspectRatio = value;
                    _invalidateResult();
                  },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('允许放大'),
            value: _allowUpscale,
            onChanged: _selected == null
                ? null
                : (value) {
                    _allowUpscale = value;
                    _invalidateResult();
                  },
          ),
          Row(
            children: [
              const Text('图片质量'),
              Expanded(
                child: Slider(
                  value: _quality,
                  min: 10,
                  max: 100,
                  divisions: 18,
                  label: '${_quality.round()}%',
                  onChanged: _selected == null
                      ? null
                      : (value) {
                          _quality = value;
                          _invalidateResult();
                        },
                ),
              ),
              Text('${_quality.round()}%'),
            ],
          ),
          const SizedBox(height: 8),
          SegmentedButton<ImageOutputFormat>(
            segments: [
              for (final format in ImageOutputFormat.values)
                ButtonSegment(value: format, label: Text(format.label)),
            ],
            selected: {_format},
            showSelectedIcon: false,
            onSelectionChanged: _selected == null
                ? null
                : (selection) {
                    _format = selection.first;
                    _invalidateResult();
                  },
          ),
          const SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('保留元数据'),
            subtitle: Text('固定关闭，避免保留位置与设备信息'),
            value: false,
            onChanged: null,
          ),
        ] else ...[
          const SizedBox(height: 16),
          const Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.shield_outlined),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text('仅在本机读取拍摄时间、设备型号、位置字段是否存在及方向；不会显示坐标或上传图片。'),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (_busy) const LinearProgressIndicator(),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              _error!,
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
        if (_mode == _ImageToolMode.optimize)
          FilledButton(
            key: const Key('optimizeImage'),
            onPressed: _selected == null || _busy ? null : _optimize,
            child: const Text('开始优化'),
          )
        else
          FilledButton.icon(
            key: const Key('inspectImageMetadata'),
            onPressed: _selected == null || _busy ? null : _inspectMetadata,
            icon: const Icon(Icons.manage_search_outlined),
            label: const Text('检查元数据'),
          ),
        if (_mode == _ImageToolMode.optimize && _optimized != null) ...[
          const SizedBox(height: 16),
          ToolResultCard(
            values: {
              '状态': '优化完成',
              '输出尺寸': '${_optimized!.width} × ${_optimized!.height}',
              '输出大小': _formatBytes(_optimized!.size),
              '已减少':
                  '${imageReductionPercent(_selected!.size, _optimized!.size).toStringAsFixed(1)}%',
            },
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: const Key('saveOptimizedImage'),
            onPressed: _busy ? null : _save,
            icon: const Icon(Icons.save_alt_outlined),
            label: const Text('保存到文件管理器'),
          ),
          if (_savedPath != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SelectableText('已保存：$_savedPath'),
            ),
        ],
        if (_mode == _ImageToolMode.privacy && _privacy != null) ...[
          const SizedBox(height: 16),
          ToolResultCard(
            values: {
              '检查结果': _privacy!.hasSensitiveMetadata ? '发现隐私相关信息' : '未发现隐私相关信息',
              '拍摄时间': _privacy!.captureTime ?? '未记录',
              '设备型号': _privacy!.cameraModel ?? '未记录',
              '位置字段': _privacy!.hasLocation ? '存在（坐标已隐藏）' : '未记录',
              '图片方向': _orientationLabel(_privacy!.orientation),
            },
          ),
          const SizedBox(height: 8),
          Text(
            _privacy!.hasSensitiveMetadata
                ? '如需分享图片，可使用“图片优化”重新编码并移除元数据。'
                : '检查范围内未发现敏感字段，但不代表文件不含其他自定义元数据。',
            style: const TextStyle(color: AppColors.muted),
          ),
        ],
        const SizedBox(height: 12),
        Text(
          _mode == _ImageToolMode.optimize
              ? '最大 20 MB / 2400 万像素 · 不上传图片\n默认移除位置等元数据'
              : '结果只在当前页面显示 · 不保存原始元数据',
          style: const TextStyle(color: AppColors.muted),
        ),
      ],
    ),
  );

  Widget _sizeField(TextEditingController controller, String label) =>
      TextField(
        controller: controller,
        enabled: _selected != null && !_busy,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        maxLength: 4,
        // 超长粘贴必须由业务校验拒绝，不能截断成另一个有效尺寸。
        maxLengthEnforcement: MaxLengthEnforcement.none,
        decoration: InputDecoration(labelText: label, counterText: ''),
        onChanged: (_) => _invalidateResult(),
      );
}
