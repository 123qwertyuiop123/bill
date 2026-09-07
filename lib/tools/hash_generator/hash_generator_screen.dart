import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/widgets/tool_widgets.dart';
import '../../core/app_theme.dart';
import 'hash_generator_logic.dart';
import 'services/file_hash_service.dart';

enum _HashMode { text, file, hmac }

class HashGeneratorScreen extends StatefulWidget {
  const HashGeneratorScreen({
    super.key,
    this.fileHashService = const FileHashService(),
  });

  final FileHashService fileHashService;

  @override
  State<HashGeneratorScreen> createState() => _HashGeneratorScreenState();
}

class _HashGeneratorScreenState extends State<HashGeneratorScreen> {
  final inputController = TextEditingController(text: 'ZM工具箱');
  final outputController = TextEditingController();
  final expectedController = TextEditingController();
  final secretController = TextEditingController();
  HashAlgorithm algorithm = HashAlgorithm.sha256;
  _HashMode mode = _HashMode.text;
  FileHashResult? fileResult;
  String? error;
  bool busy = false;
  bool obscureSecret = true;

  @override
  void dispose() {
    inputController.dispose();
    outputController.dispose();
    expectedController.dispose();
    secretController.dispose();
    super.dispose();
  }

  void _resetResult() {
    error = null;
    fileResult = null;
    outputController.clear();
  }

  void _generateText() {
    final result = generateTextHash(inputController.text, algorithm);
    setState(() {
      error = result.error;
      outputController.text = result.digest;
    });
  }

  void _generateHmac() {
    final result = generateHmac(
      secretController.text,
      inputController.text,
      algorithm,
    );
    setState(() {
      error = result.error;
      outputController.text = result.digest;
    });
  }

  Future<void> _pickAndHashFile() async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
      fileResult = null;
      outputController.clear();
    });
    try {
      final result = await widget.fileHashService.pickAndHash(algorithm);
      if (!mounted) return;
      setState(() {
        fileResult = result;
        outputController.text = result?.digest ?? '';
      });
    } on FileHashException catch (exception) {
      if (!mounted) return;
      setState(() => error = exception.message);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _copy() async {
    if (outputController.text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: outputController.text));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('哈希结果已复制')));
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) => ToolPageScaffold(
    title: '哈希生成',
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('文本摘要、文件校验与 HMAC'),
        const SizedBox(height: 16),
        SegmentedButton<_HashMode>(
          segments: const [
            ButtonSegment(value: _HashMode.text, label: Text('文本哈希')),
            ButtonSegment(value: _HashMode.file, label: Text('文件校验')),
            ButtonSegment(value: _HashMode.hmac, label: Text('HMAC')),
          ],
          selected: {mode},
          showSelectedIcon: false,
          onSelectionChanged: busy
              ? null
              : (selection) => setState(() {
                  mode = selection.first;
                  if (mode == _HashMode.hmac &&
                      algorithm != HashAlgorithm.sha256 &&
                      algorithm != HashAlgorithm.sha512) {
                    algorithm = HashAlgorithm.sha256;
                  }
                  _resetResult();
                }),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SegmentedButton<HashAlgorithm>(
            segments: [
              for (final item in HashAlgorithm.values.where(
                (item) =>
                    mode != _HashMode.hmac ||
                    item == HashAlgorithm.sha256 ||
                    item == HashAlgorithm.sha512,
              ))
                ButtonSegment(value: item, label: Text(item.label)),
            ],
            selected: {algorithm},
            showSelectedIcon: false,
            onSelectionChanged: busy
                ? null
                : (selection) => setState(() {
                    algorithm = selection.first;
                    _resetResult();
                  }),
          ),
        ),
        const SizedBox(height: 16),
        if (mode == _HashMode.text)
          ..._buildTextMode()
        else if (mode == _HashMode.file)
          ..._buildFileMode()
        else
          ..._buildHmacMode(),
      ],
    ),
  );

  List<Widget> _buildTextMode() => [
    TextField(
      key: const Key('hashInput'),
      controller: inputController,
      minLines: 7,
      maxLines: 12,
      maxLength: maxHashInputLength,
      maxLengthEnforcement: MaxLengthEnforcement.none,
      decoration: const InputDecoration(
        labelText: '输入文本',
        alignLabelWithHint: true,
      ),
    ),
    if (error != null) _ErrorText(error!),
    FilledButton(onPressed: _generateText, child: const Text('生成哈希')),
    const SizedBox(height: 16),
    _DigestField(controller: outputController),
    const SizedBox(height: 8),
    OutlinedButton.icon(
      onPressed: outputController.text.isEmpty ? null : _copy,
      icon: const Icon(Icons.copy_outlined),
      label: const Text('复制结果'),
    ),
    const SizedBox(height: 8),
    Text(
      algorithm == HashAlgorithm.md5 || algorithm == HashAlgorithm.sha1
          ? '${algorithm.label} 仅用于兼容校验，不适合安全用途或密码存储。'
          : '仅在本机计算；哈希是单向摘要，不会保存输入。',
      style: TextStyle(
        color: algorithm == HashAlgorithm.md5 || algorithm == HashAlgorithm.sha1
            ? AppColors.danger
            : AppColors.muted,
      ),
    ),
  ];

  List<Widget> _buildFileMode() {
    final expected = expectedController.text.trim();
    final hasExpected = expected.isNotEmpty;
    final validExpected = isValidDigest(expected, algorithm);
    final matches =
        fileResult != null &&
        validExpected &&
        digestsMatch(fileResult!.digest, expected, algorithm);
    return [
      if (fileResult case final result?)
        Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            title: Text(
              result.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(_formatBytes(result.size)),
          ),
        )
      else
        const Text('选择文件后将在本机计算摘要，最大支持 512 MB。'),
      if (busy) ...[
        const SizedBox(height: 12),
        const LinearProgressIndicator(),
        const SizedBox(height: 4),
        const Text('正在读取并计算，请勿关闭页面'),
      ],
      const SizedBox(height: 16),
      FilledButton.icon(
        key: const Key('pickHashFile'),
        onPressed: busy ? null : _pickAndHashFile,
        icon: const Icon(Icons.file_open_outlined),
        label: Text(fileResult == null ? '选择文件并计算' : '重新选择文件'),
      ),
      if (error != null) _ErrorText(error!),
      const SizedBox(height: 16),
      _DigestField(controller: outputController),
      const SizedBox(height: 12),
      TextField(
        key: const Key('expectedDigest'),
        controller: expectedController,
        maxLength: algorithm.digestLength,
        maxLengthEnforcement: MaxLengthEnforcement.none,
        autocorrect: false,
        enableSuggestions: false,
        decoration: InputDecoration(
          labelText: '预期摘要（可选）',
          errorText: hasExpected && !validExpected
              ? '请输入 ${algorithm.digestLength} 位十六进制摘要'
              : null,
        ),
        onChanged: (_) => setState(() {}),
      ),
      if (fileResult != null && validExpected)
        Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: matches ? AppColors.selected : null,
          child: ListTile(
            leading: Icon(
              matches ? Icons.check_circle_outline : Icons.error_outline,
              color: matches ? AppColors.primary : AppColors.danger,
            ),
            title: Text(matches ? '校验一致' : '校验不一致'),
          ),
        ),
      OutlinedButton.icon(
        onPressed: outputController.text.isEmpty ? null : _copy,
        icon: const Icon(Icons.copy_outlined),
        label: const Text('复制结果'),
      ),
      const SizedBox(height: 8),
      const Text(
        '只读取所选文件，不修改或上传。MD5 和 SHA-1 仅用于兼容校验。',
        style: TextStyle(color: AppColors.muted),
      ),
    ];
  }

  List<Widget> _buildHmacMode() => [
    TextField(
      key: const Key('hmacSecret'),
      controller: secretController,
      obscureText: obscureSecret,
      maxLength: maxHmacKeyLength,
      maxLengthEnforcement: MaxLengthEnforcement.none,
      autocorrect: false,
      enableSuggestions: false,
      decoration: InputDecoration(
        labelText: '共享密钥',
        suffixIcon: IconButton(
          tooltip: obscureSecret ? '显示密钥' : '隐藏密钥',
          onPressed: () => setState(() => obscureSecret = !obscureSecret),
          icon: Icon(
            obscureSecret
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
        ),
      ),
      onChanged: (_) => setState(_resetResult),
    ),
    const SizedBox(height: 12),
    TextField(
      key: const Key('hmacMessage'),
      controller: inputController,
      minLines: 4,
      maxLines: 8,
      maxLength: maxHashInputLength,
      maxLengthEnforcement: MaxLengthEnforcement.none,
      decoration: const InputDecoration(
        labelText: '消息内容',
        alignLabelWithHint: true,
      ),
      onChanged: (_) => setState(_resetResult),
    ),
    if (error != null) _ErrorText(error!),
    FilledButton(
      key: const Key('generateHmac'),
      onPressed: _generateHmac,
      child: const Text('生成 HMAC'),
    ),
    const SizedBox(height: 16),
    _DigestField(controller: outputController, label: 'HMAC 结果'),
    const SizedBox(height: 8),
    OutlinedButton.icon(
      onPressed: outputController.text.isEmpty ? null : _copy,
      icon: const Icon(Icons.copy_outlined),
      label: const Text('复制结果'),
    ),
    const SizedBox(height: 12),
    const Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Text('HMAC 用于消息认证，不是加密或密码哈希'),
      ),
    ),
    const SizedBox(height: 8),
    const Text('密钥和内容仅保留在当前页面', style: TextStyle(color: AppColors.muted)),
  ];
}

class _DigestField extends StatelessWidget {
  const _DigestField({required this.controller, this.label = '文件摘要 / 哈希结果'});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) => TextField(
    key: const Key('hashOutput'),
    controller: controller,
    readOnly: true,
    minLines: 3,
    maxLines: 6,
    decoration: InputDecoration(labelText: label, alignLabelWithHint: true),
  );
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.message);

  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Text(message, style: const TextStyle(color: AppColors.danger)),
  );
}
