# 第九批离线工具实施说明

日期：2026-09-20。

状态：依据用户授权，由开发代理完成 UI 自审后直接开发。

## 范围与去重

已对照 AGENTS 清单和注册表的 49 个工具：

- 色觉模拟扩展现有 `color_contrast`，不新增入口。仅模拟红色盲、绿色盲和蓝色盲颜色，不处理图片，不作医学诊断。
- 一维条码扩展现有 `qr_code`，入口名称调整为“二维码与条码”。仅生成 Code 128、EAN-13 和 UPC-A，不扫描、不使用相机。
- 固定利率贷款使用新 ID `loan_calculator`。其等额本息输入、逐期本金/利息和余额工作流未被百分比计算或 AA 分摊覆盖。

完成后注册表共 50 个工具。

## UI 自审

设计图：`offline-tools-batch-9-v1.png`，1:1 画布。

审查结论：通过。页面继续使用浅色背景、白卡、细边框、深绿色主按钮、字体图标和顶部返回栏；没有改变主导航或全局信息架构。界面使用简体中文，主要内容可滚动；结果、错误、离线说明和估算边界清晰。实现须继续验证 320×640、640×320 和两倍字体。

## 安全、性能与依赖

- 所有计算与绘制均在本机进行，不保存输入，不请求网络，不新增 Android 权限。
- 色觉模拟只处理两个有界 HEX 颜色，使用固定转换矩阵并限制输出通道。
- 贷款本金上限 10¹²、年利率 0–100%、期数 1–600；仅固定利率等额本息，不包含手续费、税费、浮动利率或个性化建议。明细使用惰性列表。
- Code 128 限 1–128 个可打印 ASCII 字符；EAN-13 和 UPC-A 严格限制数字、长度和校验位。
- 新增 `barcode_widget 2.0.4`，底层 `barcode 2.2.9`；均为 Apache-2.0，纯 Dart/Flutter 绘制，无平台权限。正式检查需包含 release APK 构建。

## 调研来源

- [ColorBlindnessFlutter](https://github.com/bernaferrari/ColorBlindnessFlutter)，MIT。
- [dart_barcode](https://github.com/DavBfr/dart_barcode)，Apache-2.0。
- [Loan-Calculator](https://github.com/wasishah33/Loan-Calculator)，MIT；仅作为功能和标准公式参考，不复制代码。

外部项目只用于功能、公式和交互调研；实现采用项目自身模块结构和安全边界。

## 实施与检查结果

2026-09-20：三项功能已按自审设计完成。颜色和条码功能分别扩展原模块，贷款工具使用独立目录并单次注册；账本、TXT 格式、公开目录同步和主导航均未修改。

- 173 个 Dart 文件通过只读格式检查，无格式变更。
- Flutter 静态分析无问题。
- 全量 218 项测试通过，包含窄屏、横屏和两倍字体测试。
- Release APK 构建成功，大小 59,857,150 字节；APK Signature Scheme v2 验证通过。
- APK SHA-256：`17E96225C0B24B48D46D1447CED0F39953D6E09CCEDC65197F167E5FF8649D52`。
- Android 目录无差异，`android/key.properties` 未被 Git 跟踪。
