const maxMimeQueryLength = 100;

enum MimeLookupMode { extension, mime }

class MimeTypeInfo {
  const MimeTypeInfo({
    required this.mime,
    required this.extensions,
    required this.category,
    required this.isText,
  });

  final String mime;
  final List<String> extensions;
  final String category;
  final bool isText;

  String get extensionsLabel => extensions.map((item) => '.$item').join('、');
}

const mimeTypeCatalog = <MimeTypeInfo>[
  MimeTypeInfo(
    mime: 'text/plain',
    extensions: ['txt', 'log'],
    category: '文本',
    isText: true,
  ),
  MimeTypeInfo(
    mime: 'text/html',
    extensions: ['html', 'htm'],
    category: '网页',
    isText: true,
  ),
  MimeTypeInfo(
    mime: 'text/css',
    extensions: ['css'],
    category: '网页',
    isText: true,
  ),
  MimeTypeInfo(
    mime: 'text/csv',
    extensions: ['csv'],
    category: '表格',
    isText: true,
  ),
  MimeTypeInfo(
    mime: 'text/markdown',
    extensions: ['md', 'markdown'],
    category: '文本',
    isText: true,
  ),
  MimeTypeInfo(
    mime: 'application/json',
    extensions: ['json', 'map'],
    category: '应用数据',
    isText: true,
  ),
  MimeTypeInfo(
    mime: 'application/xml',
    extensions: ['xml'],
    category: '应用数据',
    isText: true,
  ),
  MimeTypeInfo(
    mime: 'application/pdf',
    extensions: ['pdf'],
    category: '文档',
    isText: false,
  ),
  MimeTypeInfo(
    mime: 'application/zip',
    extensions: ['zip'],
    category: '压缩文件',
    isText: false,
  ),
  MimeTypeInfo(
    mime: 'application/gzip',
    extensions: ['gz'],
    category: '压缩文件',
    isText: false,
  ),
  MimeTypeInfo(
    mime: 'application/x-7z-compressed',
    extensions: ['7z'],
    category: '压缩文件',
    isText: false,
  ),
  MimeTypeInfo(
    mime: 'application/vnd.rar',
    extensions: ['rar'],
    category: '压缩文件',
    isText: false,
  ),
  MimeTypeInfo(
    mime: 'application/msword',
    extensions: ['doc'],
    category: '文档',
    isText: false,
  ),
  MimeTypeInfo(
    mime: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    extensions: ['docx'],
    category: '文档',
    isText: false,
  ),
  MimeTypeInfo(
    mime: 'application/vnd.ms-excel',
    extensions: ['xls'],
    category: '表格',
    isText: false,
  ),
  MimeTypeInfo(
    mime: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    extensions: ['xlsx'],
    category: '表格',
    isText: false,
  ),
  MimeTypeInfo(
    mime: 'application/vnd.ms-powerpoint',
    extensions: ['ppt'],
    category: '演示文稿',
    isText: false,
  ),
  MimeTypeInfo(
    mime: 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    extensions: ['pptx'],
    category: '演示文稿',
    isText: false,
  ),
  MimeTypeInfo(
    mime: 'application/octet-stream',
    extensions: ['bin'],
    category: '二进制',
    isText: false,
  ),
  MimeTypeInfo(
    mime: 'image/jpeg',
    extensions: ['jpg', 'jpeg'],
    category: '图片',
    isText: false,
  ),
  MimeTypeInfo(
    mime: 'image/png',
    extensions: ['png'],
    category: '图片',
    isText: false,
  ),
  MimeTypeInfo(
    mime: 'image/gif',
    extensions: ['gif'],
    category: '图片',
    isText: false,
  ),
  MimeTypeInfo(
    mime: 'image/webp',
    extensions: ['webp'],
    category: '图片',
    isText: false,
  ),
  MimeTypeInfo(
    mime: 'image/svg+xml',
    extensions: ['svg'],
    category: '图片',
    isText: true,
  ),
  MimeTypeInfo(
    mime: 'image/avif',
    extensions: ['avif'],
    category: '图片',
    isText: false,
  ),
  MimeTypeInfo(
    mime: 'audio/mpeg',
    extensions: ['mp3'],
    category: '音频',
    isText: false,
  ),
  MimeTypeInfo(
    mime: 'audio/wav',
    extensions: ['wav'],
    category: '音频',
    isText: false,
  ),
  MimeTypeInfo(
    mime: 'audio/ogg',
    extensions: ['ogg', 'oga'],
    category: '音频',
    isText: false,
  ),
  MimeTypeInfo(
    mime: 'video/mp4',
    extensions: ['mp4'],
    category: '视频',
    isText: false,
  ),
  MimeTypeInfo(
    mime: 'video/webm',
    extensions: ['webm'],
    category: '视频',
    isText: false,
  ),
  MimeTypeInfo(
    mime: 'font/woff',
    extensions: ['woff'],
    category: '字体',
    isText: false,
  ),
  MimeTypeInfo(
    mime: 'font/woff2',
    extensions: ['woff2'],
    category: '字体',
    isText: false,
  ),
];

/// 查询应用内置映射表，不访问文件系统，也不根据文件内容推断真实类型。
List<MimeTypeInfo> lookupMimeTypes(String query, MimeLookupMode mode) {
  final normalized = query.trim().toLowerCase();
  if (normalized.isEmpty) throw const FormatException('请输入查询内容');
  if (normalized.length > maxMimeQueryLength) {
    throw const FormatException('查询内容不能超过 100 个字符');
  }
  if (mode == MimeLookupMode.extension) {
    final extension = normalized.startsWith('.')
        ? normalized.substring(1)
        : normalized;
    if (!RegExp(r'^[a-z0-9][a-z0-9+_-]{0,15}$').hasMatch(extension)) {
      throw const FormatException('请输入有效的文件扩展名');
    }
    return mimeTypeCatalog
        .where((item) => item.extensions.contains(extension))
        .toList(growable: false);
  }
  if (!RegExp(r'^[a-z0-9!#$&^_.+-]+/[a-z0-9!#$&^_.+-]+$')
      .hasMatch(normalized)) {
    throw const FormatException('请输入完整的 MIME 类型，例如 application/json');
  }
  return mimeTypeCatalog
      .where((item) => item.mime == normalized)
      .toList(growable: false);
}
