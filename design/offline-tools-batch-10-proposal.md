# 第十批离线工具扩展实施说明

日期：2026-09-20。

状态：依据用户授权，由开发代理完成 UI 自审后直接开发。

## 范围与去重

已对照 `AGENTS.md` 和 `lib/tools/tool_registry.dart`：

- 密码强度评估扩展 `password_generator`，不新增入口。评估只提供保守的本地提示，不声称密码绝对安全。
- 世界时区换算扩展 `timestamp_converter`，不新增入口。继续保留原有 Unix 秒/毫秒与设备本地时间转换。
- UUID v7 扩展 `uuid_generator`，不新增入口。继续保留 UUID v4，并明确 v7 不是密码或访问令牌。

注册表工具数量保持不变。

## UI 自审

设计图：`offline-tools-batch-10-v1.png`，1:1 画布。

审查结论：通过。三个页面沿用浅色背景、白色卡片、细边框、深绿色主按钮、Material 字体图标和顶部返回栏；没有改变主导航、全局信息架构或核心工作流。界面使用简体中文，主操作明确，内容可滚动。实现继续验证窄屏、横屏和两倍字体。

## 安全、性能与依赖

- 密码和评估结果仅驻留当前页面内存，不保存、不上传、不写日志；输入上限为 256 个字符，使用显式按钮评估，避免逐键高成本计算。
- 密码评分是本地保守启发式结果，会识别长度、字符种类、常见词、重复和连续模式；它不是泄露密码查询，也不替代服务端安全策略。
- 时区换算使用内置 IANA 时区数据，不联网、不自动读取位置；拒绝夏令时跳变造成的不存在时间，并提示切换附近的歧义。
- 新增 `timezone 0.11.1`，BSD-2-Clause，由 Dart 团队维护。使用嵌入式默认数据库，不调用其网络加载接口。
- UUID v4 和 v7 均使用 `Random.secure`。v7 包含毫秒时间信息，只适合作为标识符；单批仍限制为 1 至 20 个。

## 调研来源

- [zxcvbn-dart](https://github.com/careapp-group/zxcvbn-dart)，MIT；仅作为密码模式和反馈思路参考，不复制实现或词典。
- [Dart timezone](https://github.com/dart-lang/labs/tree/main/pkgs/timezone)，BSD-2-Clause。
- [dart-uuid](https://github.com/Daegalus/dart-uuid)，MIT；依据 RFC 9562 的 v7 布局自行实现最小范围。

外部项目只用于功能、标准与交互调研；业务代码继续遵守本项目的模块和安全边界。

## 实施与检查结果

2026-09-20：三项功能均已作为原工具扩展完成，注册表工具数量保持 50 个；账本、TXT 格式、公开目录同步和主导航均未修改。

- 175 个 Dart 文件通过只读格式检查，无格式变更。
- Flutter 静态分析无问题。
- 全量 229 项测试通过，包含密码边界、夏令时无效时间、UUID v7 格式，以及窄屏、横屏和两倍字体测试。
- Release APK 构建成功，大小 60,693,590 字节；APK Signature Scheme v2 验证通过。
- APK SHA-256：`C24B3CC52384A24BA6A815070A9644E21F641C7AB44F62CDA807D890DEFC2CC7`。
- Android 目录无差异，没有新增权限；APK 仅保留既有的 Android 9 及以下公共账本写入权限和系统动态接收器保护权限。
- `android/key.properties` 未被 Git 跟踪。
