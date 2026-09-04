enum HttpStatusGroup {
  all('全部', 0),
  informational('1xx', 1),
  success('2xx', 2),
  redirect('3xx', 3),
  clientError('4xx', 4),
  serverError('5xx', 5);

  const HttpStatusGroup(this.label, this.hundreds);
  final String label;
  final int hundreds;
}

class HttpStatusInfo {
  const HttpStatusInfo({
    required this.code,
    required this.reason,
    required this.category,
    required this.description,
    required this.scenario,
    required this.suggestion,
  });

  final int code;
  final String reason;
  final String category;
  final String description;
  final String scenario;
  final String suggestion;
}

const httpStatusCatalog = <HttpStatusInfo>[
  HttpStatusInfo(
    code: 100,
    reason: 'Continue',
    category: '信息响应',
    description: '请求头已收到，客户端可以继续发送请求体。',
    scenario: '较大的上传请求',
    suggestion: '继续发送剩余请求内容。',
  ),
  HttpStatusInfo(
    code: 101,
    reason: 'Switching Protocols',
    category: '信息响应',
    description: '服务器同意切换通信协议。',
    scenario: '升级到 WebSocket',
    suggestion: '按响应头切换协议。',
  ),
  HttpStatusInfo(
    code: 200,
    reason: 'OK',
    category: '成功',
    description: '请求已成功处理。',
    scenario: '正常读取或更新资源',
    suggestion: '按响应格式处理返回内容。',
  ),
  HttpStatusInfo(
    code: 201,
    reason: 'Created',
    category: '成功',
    description: '请求成功并创建了新资源。',
    scenario: '新增记录或上传资源',
    suggestion: '读取 Location 或响应中的资源标识。',
  ),
  HttpStatusInfo(
    code: 202,
    reason: 'Accepted',
    category: '成功',
    description: '请求已接受，但尚未处理完成。',
    scenario: '异步任务',
    suggestion: '按接口约定查询任务状态。',
  ),
  HttpStatusInfo(
    code: 204,
    reason: 'No Content',
    category: '成功',
    description: '请求成功，但响应没有正文。',
    scenario: '删除或无返回值更新',
    suggestion: '不要强制解析响应正文。',
  ),
  HttpStatusInfo(
    code: 301,
    reason: 'Moved Permanently',
    category: '重定向',
    description: '资源已永久移动到新地址。',
    scenario: '站点或路径迁移',
    suggestion: '更新保存的地址并谨慎跟随重定向。',
  ),
  HttpStatusInfo(
    code: 302,
    reason: 'Found',
    category: '重定向',
    description: '资源暂时位于其他地址。',
    scenario: '临时跳转',
    suggestion: '按 Location 临时访问，不永久替换原地址。',
  ),
  HttpStatusInfo(
    code: 304,
    reason: 'Not Modified',
    category: '重定向',
    description: '缓存资源仍然有效。',
    scenario: '条件请求与浏览器缓存',
    suggestion: '继续使用本地缓存内容。',
  ),
  HttpStatusInfo(
    code: 307,
    reason: 'Temporary Redirect',
    category: '重定向',
    description: '临时重定向，并要求保持原请求方法。',
    scenario: '接口临时迁移',
    suggestion: '跟随地址且保持请求方法和请求体。',
  ),
  HttpStatusInfo(
    code: 308,
    reason: 'Permanent Redirect',
    category: '重定向',
    description: '永久重定向，并要求保持原请求方法。',
    scenario: '接口永久迁移',
    suggestion: '更新地址且保持请求方法。',
  ),
  HttpStatusInfo(
    code: 400,
    reason: 'Bad Request',
    category: '客户端错误',
    description: '服务器无法理解请求。',
    scenario: '参数、格式或语法错误',
    suggestion: '检查参数类型、编码和请求结构。',
  ),
  HttpStatusInfo(
    code: 401,
    reason: 'Unauthorized',
    category: '客户端错误',
    description: '请求缺少有效的身份验证。',
    scenario: '令牌缺失或过期',
    suggestion: '重新登录或提供有效凭据。',
  ),
  HttpStatusInfo(
    code: 403,
    reason: 'Forbidden',
    category: '客户端错误',
    description: '服务器理解请求，但拒绝执行。',
    scenario: '账号没有访问权限',
    suggestion: '检查授权范围，不要反复重试。',
  ),
  HttpStatusInfo(
    code: 404,
    reason: 'Not Found',
    category: '客户端错误',
    description: '服务器找不到请求的资源。',
    scenario: '地址错误、资源已删除',
    suggestion: '检查路径与资源是否存在。',
  ),
  HttpStatusInfo(
    code: 405,
    reason: 'Method Not Allowed',
    category: '客户端错误',
    description: '资源不支持当前请求方法。',
    scenario: '误用 GET、POST 等方法',
    suggestion: '查看 Allow 响应头或接口文档。',
  ),
  HttpStatusInfo(
    code: 408,
    reason: 'Request Timeout',
    category: '客户端错误',
    description: '服务器等待请求时超时。',
    scenario: '上传过慢或连接不稳定',
    suggestion: '确认请求可重试后再尝试。',
  ),
  HttpStatusInfo(
    code: 409,
    reason: 'Conflict',
    category: '客户端错误',
    description: '请求与资源当前状态冲突。',
    scenario: '版本冲突或重复创建',
    suggestion: '刷新资源状态后解决冲突。',
  ),
  HttpStatusInfo(
    code: 413,
    reason: 'Content Too Large',
    category: '客户端错误',
    description: '请求内容超过服务器允许的大小。',
    scenario: '文件或请求体过大',
    suggestion: '压缩、分块或降低请求大小。',
  ),
  HttpStatusInfo(
    code: 415,
    reason: 'Unsupported Media Type',
    category: '客户端错误',
    description: '服务器不支持请求内容类型。',
    scenario: 'Content-Type 设置错误',
    suggestion: '使用接口支持的媒体类型。',
  ),
  HttpStatusInfo(
    code: 422,
    reason: 'Unprocessable Content',
    category: '客户端错误',
    description: '请求格式正确，但内容无法处理。',
    scenario: '字段校验失败',
    suggestion: '根据错误字段修正业务数据。',
  ),
  HttpStatusInfo(
    code: 429,
    reason: 'Too Many Requests',
    category: '客户端错误',
    description: '请求频率超过服务限制。',
    scenario: '触发接口限流',
    suggestion: '读取 Retry-After 并延迟重试。',
  ),
  HttpStatusInfo(
    code: 500,
    reason: 'Internal Server Error',
    category: '服务器错误',
    description: '服务器处理请求时发生内部错误。',
    scenario: '服务端异常',
    suggestion: '记录请求标识并稍后重试或联系服务方。',
  ),
  HttpStatusInfo(
    code: 501,
    reason: 'Not Implemented',
    category: '服务器错误',
    description: '服务器不支持完成请求所需的功能。',
    scenario: '方法或能力尚未实现',
    suggestion: '确认服务端支持范围。',
  ),
  HttpStatusInfo(
    code: 502,
    reason: 'Bad Gateway',
    category: '服务器错误',
    description: '网关从上游服务收到无效响应。',
    scenario: '反向代理或上游故障',
    suggestion: '稍后重试并检查上游服务。',
  ),
  HttpStatusInfo(
    code: 503,
    reason: 'Service Unavailable',
    category: '服务器错误',
    description: '服务暂时不可用。',
    scenario: '维护、过载或依赖故障',
    suggestion: '参考 Retry-After 后重试。',
  ),
  HttpStatusInfo(
    code: 504,
    reason: 'Gateway Timeout',
    category: '服务器错误',
    description: '网关等待上游服务响应超时。',
    scenario: '上游处理过慢或网络故障',
    suggestion: '稍后重试并检查上游超时设置。',
  ),
];

/// 仅查询内置常量，不解释 URL，也不会发起任何网络请求。
List<HttpStatusInfo> searchHttpStatuses(String query, HttpStatusGroup group) {
  final normalized = query.trim().toLowerCase();
  if (normalized.length > 64) {
    throw const FormatException('查询内容不能超过 64 个字符');
  }
  return httpStatusCatalog
      .where((item) {
        final inGroup =
            group == HttpStatusGroup.all || item.code ~/ 100 == group.hundreds;
        if (!inGroup) return false;
        if (normalized.isEmpty) return true;
        return item.code.toString().contains(normalized) ||
            item.reason.toLowerCase().contains(normalized) ||
            item.category.contains(normalized) ||
            item.description.contains(normalized) ||
            item.scenario.contains(normalized);
      })
      .toList(growable: false);
}
