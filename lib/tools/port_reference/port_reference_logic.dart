const maxPortQueryLength = 64;

enum PortProtocolFilter { all, tcp, udp }

enum PortProtocol {
  tcp('TCP'),
  udp('UDP'),
  both('TCP/UDP');

  const PortProtocol(this.label);
  final String label;
}

class PortInfo {
  const PortInfo({
    required this.port,
    required this.protocol,
    required this.service,
    required this.purpose,
    required this.advice,
  });

  final int port;
  final PortProtocol protocol;
  final String service;
  final String purpose;
  final String advice;
}

const commonPorts = <PortInfo>[
  PortInfo(
    port: 20,
    protocol: PortProtocol.tcp,
    service: 'FTP 数据',
    purpose: '传统 FTP 数据传输',
    advice: '优先使用加密传输方案',
  ),
  PortInfo(
    port: 21,
    protocol: PortProtocol.tcp,
    service: 'FTP 控制',
    purpose: '传统 FTP 控制连接',
    advice: 'FTP 默认不加密凭据',
  ),
  PortInfo(
    port: 22,
    protocol: PortProtocol.tcp,
    service: 'SSH',
    purpose: '安全远程登录与文件传输',
    advice: '使用密钥并限制公网来源',
  ),
  PortInfo(
    port: 23,
    protocol: PortProtocol.tcp,
    service: 'Telnet',
    purpose: '明文远程终端',
    advice: '不建议在不可信网络使用',
  ),
  PortInfo(
    port: 25,
    protocol: PortProtocol.tcp,
    service: 'SMTP',
    purpose: '邮件服务器之间投递',
    advice: '客户端发信通常使用 587',
  ),
  PortInfo(
    port: 53,
    protocol: PortProtocol.both,
    service: 'DNS',
    purpose: '域名解析',
    advice: '开放递归服务应限制访问',
  ),
  PortInfo(
    port: 67,
    protocol: PortProtocol.udp,
    service: 'DHCP 服务端',
    purpose: '分配网络配置',
    advice: '通常只应出现在受信局域网',
  ),
  PortInfo(
    port: 68,
    protocol: PortProtocol.udp,
    service: 'DHCP 客户端',
    purpose: '接收网络配置',
    advice: '通常只应出现在受信局域网',
  ),
  PortInfo(
    port: 69,
    protocol: PortProtocol.udp,
    service: 'TFTP',
    purpose: '简单文件传输',
    advice: '无认证，避免暴露到公网',
  ),
  PortInfo(
    port: 80,
    protocol: PortProtocol.tcp,
    service: 'HTTP',
    purpose: '未加密网页服务',
    advice: '敏感内容应使用 HTTPS',
  ),
  PortInfo(
    port: 110,
    protocol: PortProtocol.tcp,
    service: 'POP3',
    purpose: '接收邮件',
    advice: '优先使用加密的 POP3S',
  ),
  PortInfo(
    port: 123,
    protocol: PortProtocol.udp,
    service: 'NTP',
    purpose: '网络时间同步',
    advice: '公网服务应防止放大攻击',
  ),
  PortInfo(
    port: 143,
    protocol: PortProtocol.tcp,
    service: 'IMAP',
    purpose: '同步邮件',
    advice: '优先使用 TLS 或 IMAPS',
  ),
  PortInfo(
    port: 161,
    protocol: PortProtocol.udp,
    service: 'SNMP',
    purpose: '网络设备监控',
    advice: '避免使用默认团体字符串',
  ),
  PortInfo(
    port: 389,
    protocol: PortProtocol.both,
    service: 'LDAP',
    purpose: '目录服务',
    advice: '敏感查询应使用 TLS',
  ),
  PortInfo(
    port: 443,
    protocol: PortProtocol.tcp,
    service: 'HTTPS',
    purpose: '加密网页服务',
    advice: '仍需正确配置证书与协议',
  ),
  PortInfo(
    port: 445,
    protocol: PortProtocol.tcp,
    service: 'SMB',
    purpose: 'Windows 文件和打印共享',
    advice: '不应直接暴露到公网',
  ),
  PortInfo(
    port: 465,
    protocol: PortProtocol.tcp,
    service: 'SMTPS',
    purpose: '隐式 TLS 邮件提交',
    advice: '确认服务端采用现代 TLS',
  ),
  PortInfo(
    port: 587,
    protocol: PortProtocol.tcp,
    service: 'SMTP 提交',
    purpose: '邮件客户端提交邮件',
    advice: '启用认证与 STARTTLS',
  ),
  PortInfo(
    port: 636,
    protocol: PortProtocol.tcp,
    service: 'LDAPS',
    purpose: 'TLS 目录服务',
    advice: '验证服务端证书',
  ),
  PortInfo(
    port: 993,
    protocol: PortProtocol.tcp,
    service: 'IMAPS',
    purpose: 'TLS 邮件同步',
    advice: '验证邮件服务器证书',
  ),
  PortInfo(
    port: 995,
    protocol: PortProtocol.tcp,
    service: 'POP3S',
    purpose: 'TLS 邮件接收',
    advice: '验证邮件服务器证书',
  ),
  PortInfo(
    port: 1433,
    protocol: PortProtocol.tcp,
    service: 'Microsoft SQL Server',
    purpose: '数据库连接',
    advice: '限制来源并避免公网直连',
  ),
  PortInfo(
    port: 1521,
    protocol: PortProtocol.tcp,
    service: 'Oracle 数据库',
    purpose: '数据库监听连接',
    advice: '限制来源并及时更新',
  ),
  PortInfo(
    port: 2049,
    protocol: PortProtocol.both,
    service: 'NFS',
    purpose: '网络文件系统',
    advice: '仅在可信网络开放',
  ),
  PortInfo(
    port: 3306,
    protocol: PortProtocol.tcp,
    service: 'MySQL',
    purpose: '数据库连接',
    advice: '限制来源并使用独立账号',
  ),
  PortInfo(
    port: 3389,
    protocol: PortProtocol.both,
    service: 'RDP',
    purpose: 'Windows 远程桌面',
    advice: '建议经 VPN 访问并启用 NLA',
  ),
  PortInfo(
    port: 5432,
    protocol: PortProtocol.tcp,
    service: 'PostgreSQL',
    purpose: '数据库连接',
    advice: '限制监听地址和来源',
  ),
  PortInfo(
    port: 5672,
    protocol: PortProtocol.tcp,
    service: 'AMQP',
    purpose: '消息队列连接',
    advice: '启用认证与加密',
  ),
  PortInfo(
    port: 6379,
    protocol: PortProtocol.tcp,
    service: 'Redis',
    purpose: '内存数据服务',
    advice: '禁止无认证公网暴露',
  ),
  PortInfo(
    port: 8080,
    protocol: PortProtocol.tcp,
    service: 'HTTP 备用',
    purpose: '常见开发或代理网页端口',
    advice: '具体用途取决于本机服务',
  ),
  PortInfo(
    port: 8443,
    protocol: PortProtocol.tcp,
    service: 'HTTPS 备用',
    purpose: '常见备用加密网页端口',
    advice: '具体用途取决于本机服务',
  ),
  PortInfo(
    port: 27017,
    protocol: PortProtocol.tcp,
    service: 'MongoDB',
    purpose: '数据库连接',
    advice: '启用认证并限制来源',
  ),
];

/// 只查询内置静态资料，不创建 Socket，也不判断设备上的真实端口占用情况。
List<PortInfo> lookupPorts(String query, PortProtocolFilter filter) {
  final normalized = query.trim().toLowerCase();
  if (normalized.length > maxPortQueryLength) {
    throw const FormatException('查询内容不能超过 64 个字符');
  }
  int? requestedPort;
  if (RegExp(r'^\d+$').hasMatch(normalized)) {
    requestedPort = int.tryParse(normalized);
    if (requestedPort == null || requestedPort < 0 || requestedPort > 65535) {
      throw const FormatException('端口号必须在 0–65535 之间');
    }
  }

  return commonPorts
      .where((item) {
        final protocolMatches = switch (filter) {
          PortProtocolFilter.all => true,
          PortProtocolFilter.tcp => item.protocol != PortProtocol.udp,
          PortProtocolFilter.udp => item.protocol != PortProtocol.tcp,
        };
        if (!protocolMatches) return false;
        if (normalized.isEmpty) return true;
        if (requestedPort != null) return item.port == requestedPort;
        return item.service.toLowerCase().contains(normalized) ||
            item.purpose.toLowerCase().contains(normalized) ||
            item.protocol.label.toLowerCase().contains(normalized);
      })
      .toList(growable: false);
}
