import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../app/widgets/tool_result_widgets.dart';
import '../../app/widgets/tool_widgets.dart';
import '../../core/app_theme.dart';
import 'qr_code_logic.dart';

enum _CodeMode { qr, linear }

/// 二维码和一维条码都只在本机绘制，不访问相机、网络或相册。
class QrCodeScreen extends StatefulWidget {
  const QrCodeScreen({super.key});

  @override
  State<QrCodeScreen> createState() => _QrCodeScreenState();
}

class _QrCodeScreenState extends State<QrCodeScreen> {
  final controller = TextEditingController();
  _CodeMode mode = _CodeMode.qr;
  LinearBarcodeType barcodeType = LinearBarcodeType.code128;
  String data = '';
  String? error;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _invalidate() => setState(() {
    data = '';
    error = null;
  });

  void _generate() => setState(() {
    data = '';
    error = null;
    // 二维码可以承载空格等原始文本，生成时不得静默改写用户输入。
    final raw = controller.text;
    if (raw.isEmpty) {
      error = '请先输入内容';
      return;
    }
    if (mode == _CodeMode.qr) {
      if (raw.length > 1000) {
        error = '二维码内容不能超过 1000 个字符';
        return;
      }
      data = raw;
      return;
    }
    try {
      data = normalizeLinearBarcode(raw, barcodeType);
    } on FormatException catch (exception) {
      error = exception.message;
    }
  });

  Barcode _barcode() => switch (barcodeType) {
    LinearBarcodeType.code128 => Barcode.code128(),
    LinearBarcodeType.ean13 => Barcode.ean13(),
    LinearBarcodeType.upcA => Barcode.upcA(),
  };

  @override
  Widget build(BuildContext context) => ToolPageScaffold(
    title: '二维码与条码',
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        SegmentedButton<_CodeMode>(
          segments: const [
            ButtonSegment(value: _CodeMode.qr, label: Text('二维码')),
            ButtonSegment(value: _CodeMode.linear, label: Text('一维条码')),
          ],
          selected: {mode},
          showSelectedIcon: false,
          onSelectionChanged: (selection) => setState(() {
            mode = selection.first;
            data = '';
            error = null;
          }),
        ),
        const SizedBox(height: 16),
        if (mode == _CodeMode.linear) ...[
          DropdownButtonFormField<LinearBarcodeType>(
            key: const Key('barcodeType'),
            initialValue: barcodeType,
            isExpanded: true,
            decoration: const InputDecoration(labelText: '条码格式'),
            items: LinearBarcodeType.values
                .map(
                  (type) =>
                      DropdownMenuItem(value: type, child: Text(type.label)),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                barcodeType = value;
                data = '';
                error = null;
              });
            },
          ),
          const SizedBox(height: 12),
        ],
        TextField(
          key: const Key('codeInput'),
          controller: controller,
          minLines: mode == _CodeMode.qr ? 3 : 1,
          maxLines: mode == _CodeMode.qr ? 6 : 1,
          maxLength: mode == _CodeMode.qr ? 1000 : 128,
          maxLengthEnforcement: MaxLengthEnforcement.none,
          autocorrect: false,
          enableSuggestions: false,
          decoration: InputDecoration(
            labelText: mode == _CodeMode.qr ? '文字或网址' : '条码内容',
            alignLabelWithHint: mode == _CodeMode.qr,
          ),
          onChanged: (_) => _invalidate(),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              error!,
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
        FilledButton.icon(
          key: const Key('generateCode'),
          onPressed: _generate,
          icon: Icon(
            mode == _CodeMode.qr
                ? Icons.qr_code_2_outlined
                : Icons.view_week_outlined,
          ),
          label: Text(mode == _CodeMode.qr ? '生成二维码' : '生成条码'),
        ),
        if (data.isNotEmpty) ...[
          const SizedBox(height: 24),
          Card(
            margin: EdgeInsets.zero,
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: mode == _CodeMode.qr
                  ? Center(
                      child: QrImageView(
                        data: data,
                        version: QrVersions.auto,
                        size: 230,
                        errorCorrectionLevel: QrErrorCorrectLevel.M,
                        errorStateBuilder: (context, error) => const SizedBox(
                          width: 230,
                          height: 230,
                          child: Center(child: Text('内容过长，无法生成二维码')),
                        ),
                      ),
                    )
                  : SizedBox(
                      height: 170,
                      child: BarcodeWidget(
                        barcode: _barcode(),
                        data: data,
                        drawText: true,
                        errorBuilder: (context, error) =>
                            const Center(child: Text('内容不符合所选条码格式')),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          CopyResultButton(text: data),
          const SizedBox(height: 4),
          Center(child: Text(data, key: const Key('generatedCodeText'))),
        ],
        const SizedBox(height: 12),
        Text(
          mode == _CodeMode.qr
              ? '二维码完全在本机生成，不上传输入内容。'
              : '一维条码仅在本机生成；不启用相机扫描，EAN/UPC 会校验并补全校验位。',
          style: const TextStyle(color: AppColors.muted),
        ),
      ],
    ),
  );
}
