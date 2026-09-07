# 第五批离线工具设计提案

状态：**用户已确认；两个新工具及 HMAC、HTML 实体扩展已实现并注册。**

## GitHub 搜索与筛选

本批参考了 IT-Tools 的离线工具目录、Dart 官方 `crypto` 实现、Dart Image Library、`flutter_image_compress` 以及其他开源离线工具箱。筛选仍以完全离线、低权限、手机端操作清晰、资源边界可控为前提。

| 页面 | 去重结论 | 设计范围 |
|---|---|---|
| 图片优化 | 新工具，稳定 ID 预定为 `image_optimizer` | 用户主动选择单张图片；缩放、质量压缩和 JPEG/PNG/WebP 转换；默认保持比例、禁止放大、移除元数据；最大 20 MB、2400 万像素；处理后由用户保存到文件管理器 |
| 宽高比计算 | 新工具，稳定 ID 预定为 `aspect_ratio_calculator` | 约分宽高比、显示小数比例和方向，按锁定比例换算目标尺寸，提供常见比例预设；只处理数字，不读取图片 |
| HMAC | 与 `hash_generator` 的算法、输入和摘要输出流程高度重合，必须扩展原工具，不新增稳定 ID | 在现有“文本哈希 / 文件校验”后增加 HMAC 模式；仅支持 SHA-256、SHA-512；共享密钥默认隐藏且不持久化；明确 HMAC 不是加密或密码哈希 |
| HTML 实体 | 属于通用文本转换，必须扩展 `text_tools`，不新增稳定 ID | 编码常用特殊字符；严格解码有分号的常用命名实体及十进制/十六进制数字实体；未知或越界实体保留原文；从不渲染或执行 HTML |

注册表已从 35 个增加到 37 个，只新增 `image_optimizer` 和 `aspect_ratio_calculator`。

## 图片处理安全与性能边界

- 首版面向 Android，使用系统文档选择器读取用户主动选择的单张图片，不申请“所有文件访问权限”。
- 输入文件最大 20 MB，解码前后校验尺寸，最大 2400 万像素；异常图片、超大图片和不支持格式必须安全拒绝。
- 解码、缩放和编码不得放在 UI 线程；页面只在用户点击“开始优化”后处理。
- 默认保持宽高比并禁止放大，目标边长设上限，避免无意义放大和内存峰值。
- 默认移除 EXIF 中的位置、设备等元数据；如允许保留，界面必须明确隐私影响。
- 结果先作为临时预览，只有用户点击保存后才写入公开目录；覆盖同名文件必须确认或自动生成不冲突名称。
- 输出应通过 Android MediaStore 保存到文件管理器可见位置，不拼接未经校验的用户路径。

## 去重后暂不加入

- 单独的图片格式转换、图片压缩、图片缩放、EXIF 移除：主要流程均属于“图片优化”，应继续扩展同一模块。
- 密码强度分析：应扩展现有 `password_generator`，不能另建同类密码工具。
- Unicode、大小写、Slug、HTML 字符转换：通用文本转换应优先扩展 `text_tools`。
- JSON/YAML/XML/TOML 转换：与现有 `json_tool` 和 `csv_json_converter` 部分重合，需要另行设计统一的数据格式转换入口。
- 罗马数字转换：应扩展现有 `number_base_converter`。
- 图片裁剪和 EXIF 查看：操作与权限范围明显更大，留待“图片优化”稳定后单独评审。

## UI 约束

- 继续使用白底、深绿色主色、细边框、轻圆角和 Material 字体图标。
- 普通组件全部使用简体中文；HMAC、HTML、JPEG、PNG、WebP、SHA 等标准名称保留英文。
- 工具详情页不显示底部导航，主导航仍限定为：首页、分类、收藏、设置。
- 每页明确离线状态、输入上限、数据去向和容易误解的安全边界。

## GitHub 参考

- IT-Tools 工具目录：https://github.com/CorentinTh/it-tools/tree/main/src/tools
- Dart `crypto`（包含 HMAC）：https://github.com/dart-lang/core/tree/main/pkgs/crypto
- Dart Image Library：https://github.com/brendan-duncan/image
- Flutter Image Compress：https://github.com/fluttercandies/flutter_image_compress
- CapyToolkit 离线工具分类：https://github.com/capytoolkit/capytoolkit
- CVToolkit 图片与宽高比工具：https://github.com/osscv/CVToolkit

## 设计文件

- `design/offline-tools-batch-5-v1.png`
- `design/offline-tools-batch-5-prompt.md`
