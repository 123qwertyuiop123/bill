# 第六批离线工具 UI 设计图生成提示词

Use case: ui-mockup

Asset type: ZM 工具箱第六批离线工具的 1:1 中文移动端 UI 总览

Primary request: 生成一张 1024×1024 的高保真但朴素轻量的 Flutter Android UI 设计图，画面以 2×2 网格展示四个独立手机页面：YAML/JSON 转换、XML 工具、Unicode 检查、端口号参考。

Style/medium: 接近真实 Flutter Material 界面的产品设计稿；浅灰绿色背景、白色卡片、深绿色主按钮和强调色、细灰色边框、小圆角、极轻阴影；只使用简单 Material 字体图标，不使用插画或图片分类图标。

Composition/framing: 正方形画布，四台等大的手机界面完整可见，2×2 均匀排列，留出足够间距。每个页面都有顶部返回箭头和中文标题，不显示工具箱底部导航。

Screen 1 text and layout: 标题“YAML/JSON 转换”；分段按钮“YAML → JSON”“JSON → YAML”；输入卡片标题“输入内容”，示例 `name: ZM工具箱` 与 `offline: true`；深绿色按钮“开始转换”；结果卡片标题“转换结果”，内容展示格式化 JSON；底部“复制结果”。

Screen 2 text and layout: 标题“XML 工具”；分段按钮“格式化”“压缩”“校验”；输入卡片标题“XML 内容”，示例 `<note><title>提醒</title></note>`；深绿色按钮“格式化 XML”；结果卡显示“格式正确”“2 个元素”，下面展示缩进后的 XML。

Screen 3 text and layout: 标题“Unicode 检查”；输入框标题“输入字符”，示例“中A😊”；筛选按钮“全部字符”“仅 ASCII”；结果以紧凑表格卡片显示三行：字符、码点、UTF-8，其中包含 `中  U+4E2D`、`A  U+0041`、`😊  U+1F60A`；底部按钮“复制结果”。

Screen 4 text and layout: 标题“端口号参考”；搜索框占位“输入端口号或服务名”；筛选标签“全部”“TCP”“UDP”；结果卡片显示“80 · TCP  HTTP”“443 · TCP  HTTPS”“53 · TCP/UDP  DNS”；底部浅色安全提示“仅查询内置资料，不扫描网络”。

Text (verbatim): “YAML/JSON 转换”, “XML 工具”, “Unicode 检查”, “端口号参考”, “开始转换”, “格式化 XML”, “复制结果”, “仅查询内置资料，不扫描网络”.

Constraints: 所有普通 UI 文案必须为简体中文；标准技术名保持英文；字号清晰；页面层次简洁；表现手机竖屏滚动页面；视觉风格与现有 ZM 工具箱一致。

Avoid: 英文导航文案、分类插画、照片、彩色工具图标、渐变背景、玻璃拟态、重阴影、霓虹、高成本动画暗示、水印、品牌 Logo、底部主导航、乱码和密集装饰。
