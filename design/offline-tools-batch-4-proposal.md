# 第四批离线工具设计提案

状态：**用户已确认；三个新工具和文件哈希扩展已实现、注册并通过自动检查与正式构建。**

## GitHub 调研与筛选结果

本批候选参考了 Flutter 官方文件选择器、Dart 官方加密库、IT-Tools 的离线工具目录，以及开源 Markdown 渲染实现。筛选原则是完全离线、低权限、无需接口、不嵌入密钥，并优先复用现有模块。

| 页面 | 去重结论 | 计划范围 |
|---|---|---|
| 哈希生成：文件校验 | 与现有 `hash_generator` 部分重复，必须扩展原工具，不新增稳定 ID | 用户主动选择文件；分块计算 MD5、SHA-1、SHA-256 或 SHA-512；可与预期摘要比较；只读、不上传、不修改 |
| Markdown 预览 | 与 `text_tools` 不重复，属于独立的排版预览流程 | 有界文本输入；本地渲染常用 Markdown；禁用 HTML、脚本、远程资源及自动打开链接 |
| HTTP 状态码 | 无重复 | 使用内置静态数据按状态码或关键词查询；提供中文含义、常见场景和处理建议；绝不发起 HTTP 请求 |
| MIME 类型 | 无重复 | 使用内置静态表按扩展名或 MIME 类型查询；不读取文件内容，不做文件嗅探 |

注册表已从 32 个工具增加到 35 个：新增 `markdown_preview`、`http_status_reference`、`mime_type_reference`，并扩展已有 `hash_generator`。

## 暂缓候选

- 图片缩放/压缩：功能不重复，但涉及图片解码内存上限、元数据处理、输出目录和 Android 文件授权；留待单独设计和资源边界评审。
- 罗马数字转换：主要操作属于进制/数字表示转换，应优先扩展现有 `number_base_converter`，不创建同类工具。
- 文件哈希校验器：不单独建工具，已并入本批“哈希生成”。

## UI 约束

- 延续已确认的朴素白底、深绿色主色、细边框和字体图标风格。
- 所有操作组件使用中文；Markdown、HTTP、MIME 和算法名称保留标准英文。
- 工具详情页不增加底部导航，主导航仍限定为：首页、分类、收藏、设置。
- 页面直接展示安全边界，避免用户误以为会联网、执行内容或修改文件。

## 参考项目

- Flutter `file_selector`：https://github.com/flutter/packages/tree/main/packages/file_selector/file_selector
- Dart `crypto`：https://github.com/dart-lang/core/tree/main/pkgs/crypto
- IT-Tools 工具目录：https://github.com/CorentinTh/it-tools/tree/main/src/tools
- Flutter Markdown 已停止维护的迁移背景：https://github.com/flutter/flutter/issues/162966

## 设计文件

- `design/offline-tools-batch-4-v1.png`
- `design/offline-tools-batch-4-prompt.md`

## 实现检查记录（2026-09-04）

- 格式检查：119 个 Dart 文件，0 项变更。
- 静态分析：无问题。
- 完整测试：128 项通过，包含账本兼容、新增工具边界、文件哈希摘要比较与平台失败降级。
- 正式构建：`flutter build apk --release --no-pub` 成功。
- 文件哈希使用 Android 系统文档选择器提供的单文件临时只读能力；无新增 Android 权限，不保存 URI、路径或文件内容。
- 限制：未安装到 Android 真机验证系统文档提供方差异；Markdown 仅支持设计中约定的安全子集，HTTP 与 MIME 数据为有界内置参考表。
