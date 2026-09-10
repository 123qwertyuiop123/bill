# 第六批离线工具提案

状态：UI 已由用户确认，允许按本文范围进行组件化开发。

## GitHub 调研来源

- [DevToys](https://github.com/DevToys-app/DevToys)：提供 JSON/YAML 转换、XML 格式化与验证等离线小工具思路。
- [CyberChef](https://github.com/gchq/CyberChef)：其操作分类包含 YAML/JSON、Unicode 和多种数据格式处理，可作为输入输出边界的参考。
- [dev-toolbox](https://github.com/vdtdg/dev-toolbox)：包含 YAML/JSON、XML、ASCII 参考等隐私优先工具。
- [developer-toolbox](https://github.com/wuwx/developer-toolbox)：包含 Unicode 转换、XML、YAML 等客户端处理工具。
- [it-tools-mcp](https://github.com/wrenchpilot/it-tools-mcp)：工具清单包含 Unicode 信息与常用端口号查询。

只参考功能方向与交互习惯，不复制第三方代码、素材或品牌视觉。

## 去重结果

已逐项对照 `AGENTS.md` 和 `lib/tools/tool_registry.dart` 中的 37 个工具。

| 稳定 ID | 中文名 | 去重结论 | 主要功能 |
|---|---|---|---|
| `yaml_json_converter` | YAML/JSON 转换 | 新工具；现有 JSON 工具只格式化、压缩和校验 JSON，没有 YAML 解析或双向转换 | YAML 转 JSON、JSON 转 YAML、复制结果 |
| `xml_tool` | XML 工具 | 新工具；现有 JSON、CSV/JSON、Markdown 工具均不解析 XML | 格式化、压缩、结构校验 |
| `unicode_inspector` | Unicode 检查 | 新工具；文本工具只做统计、大小写、清理和 HTML 实体，不展示字符编码结构 | 按字符查看码点、UTF-8、UTF-16 和转义形式 |
| `port_reference` | 端口号参考 | 新工具；HTTP 状态码和 MIME 类型是不同的数据表，IPv4 工具只计算 CIDR | 按端口或服务名查询内置常用 TCP/UDP 资料 |

不单独增加“ASCII 表”：ASCII 是 Unicode 的子集，超过一半主要能力会与 `unicode_inspector` 重复，设计为 Unicode 页面内的“仅 ASCII”快捷筛选。

JSONPath 暂不单独增加：它应在未来扩展现有 `json_tool`，避免出现第二个 JSON 页面。

## 页面与安全边界

### YAML/JSON 转换

- 顶部双向模式：`YAML → JSON`、`JSON → YAML`。
- 输入、转换、结果三个清晰区域；结果提供复制。
- 完全离线，不读写文件，不保存输入。
- 建议上限：输入 200 KB、最多 5000 个节点、嵌套深度 64、输出 1 MB。
- 只接受可转换为 JSON 的标量、列表和字符串键映射；拒绝自定义标签和不安全对象构造。

### XML 工具

- 顶部模式：`格式化`、`压缩`、`校验`。
- 输入区下方只保留一个主按钮，结果卡显示状态、行列提示或转换结果。
- 完全离线，不加载 URL，不解析外部资源。
- 建议上限：输入 200 KB、最多 5000 个节点、嵌套深度 64、输出 1 MB。
- 明确禁用 DTD、外部实体和网络实体，防止 XXE 与实体膨胀。

### Unicode 检查

- 输入少量文本后，按 Unicode 标量逐项展示字符、`U+` 码点、UTF-8、UTF-16 和 Dart/JSON 转义。
- 提供“全部字符 / 仅 ASCII”筛选与结果复制。
- 输入最多 256 个 Unicode 标量，最多展示 256 行；不保存内容。
- 不声称进行字体检测、语言识别或同形字符安全判定。

### 端口号参考

- 搜索框支持端口号或服务名，筛选 `全部 / TCP / UDP`。
- 使用应用内置的有限常用端口表，显示端口、协议、常见用途和简短安全提示。
- 完全离线，不执行端口扫描、DNS、Socket 或 HTTP 请求。
- 查询长度上限 64；端口只接受 `0–65535`。
- 资料仅供快速参考，不宣称代表设备实时占用或权威注册状态。

## UI 规范

- 1:1 总览设计图，四个手机页面以 2×2 排列。
- 延续深绿色主色、浅灰绿背景、白色卡片、细边框和 Material 字体图标。
- 全部普通界面文案使用简体中文；YAML、JSON、XML、Unicode、TCP、UDP 等标准名保留英文。
- 不使用分类插画、复杂渐变、重阴影、玻璃模糊或高成本动画。
- 每个页面均可滚动，并为错误、空结果和超限状态预留位置。

## 用户确认后的开发顺序

1. 先确认解析依赖的维护状态、许可证和包体积；能安全自实现的逻辑不额外引入依赖。
2. 每个工具建立独立 `lib/tools/<tool_name>/` 目录并补齐逻辑、页面和测试。
3. 在注册表中各注册一次，并同步更新 `AGENTS.md`、README 和工具总数。
4. 按开发规范依次执行格式检查、静态分析、完整测试；若新增依赖，再执行正式 APK 构建与签名检查。
