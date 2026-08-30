# Bill 收支账本

一款简洁的 Flutter 本地收支记录 App。支持收入、支出、分类统计、多 TXT 账本切换，并在 Android 手机上自动生成文件管理器可见的月度 TXT。

![界面设计](design/income-expense-ui-no-category-icons.png)

## 功能

- 记录收入和支出原因、金额、分类与日期
- 按天查看、添加、修改和删除记录
- 按月份统计收入、支出、结余及消费种类
- 每个月自动创建默认 TXT
- 在同一个月份新建多个独立 TXT，并在文件之间切换
- 每个 TXT 的记录与统计互相隔离
- 自定义 TXT 文件名
- 每个 TXT 可单独选择行首格式
- 修改记录后自动更新公共 TXT，无需手动下载

## TXT 格式

基本规则：

- 每个日期占一行
- 同一天的多笔记录使用英文逗号 `,` 分隔
- 支出金额不带减号
- 只有收入金额带 `+`
- 原因中的换行、英文逗号和英文冒号会被安全转换，避免破坏文件结构

每个 TXT 可以独立选择以下格式。

日期开头（默认）：

```text
1日:午饭:18.8,工资:+6200
2日:公交:2,晚饭:25
```

完整日期开头：

```text
2026年8月1日:午饭:18.8,工资:+6200
2026年8月2日:公交:2,晚饭:25
```

TXT 是 App 自动生成的副本。请通过 App 修改账目，不要直接编辑公共 TXT，否则下一次同步会覆盖手工修改。

## Android 文件位置

首次打开 App 后会创建当年目录和当月默认 TXT：

```text
/storage/emulated/0/Download/bill/2026/2026年8月消费.txt
```

创建多个文件后的示例：

```text
Download/
└── bill/
    ├── 2026/
    │   ├── 2026年8月消费.txt
    │   ├── 家庭.txt
    │   └── 工作报销.txt
    └── 2027/
        └── 2027年1月消费.txt
```

Android 10 及以上通过 MediaStore 写入公共下载目录，不申请“所有文件访问权限”。Android 9 及以下首次保存时需要传统存储权限。应用内部还会保留主账本，公共 TXT 被误删不会直接删除 App 内记录。

## 使用方法

1. 点击“记一笔”，选择收入或支出并填写内容。
2. 点击月份区域左右按钮切换月份。
3. 点击 TXT 文件卡片切换当前文件。
4. 点击文件卡片右侧的新建图标创建空白 TXT。
5. 点击格式图标选择“日期开头”或“完整日期开头”。
6. 点击铅笔图标修改当前 TXT 名称。

## 项目信息

- Flutter/Dart 项目
- Android Application ID：`com.zm.bill`
- iOS Bundle ID：`com.zm.bill`
- 当前版本：`1.0.0+1`
- 数据仅保存在本地，不上传服务器

主要目录：

```text
lib/
├── controllers/    # 账本状态与业务流程
├── core/           # 主题和通用配置
├── models/         # 收支、分类和 TXT 文件模型
├── screens/        # 账本、详情和统计页面
├── services/       # 内部存储与公共 TXT 同步
├── utils/          # 日期等工具
└── widgets/        # 表单、日历和通用组件
```

## 开发环境

安装 Flutter SDK 和 Android Studio，并确认环境正常：

```powershell
flutter doctor
```

获取依赖并运行：

```powershell
flutter pub get
flutter run
```

代码检查与测试：

```powershell
flutter analyze
flutter test
```

## 正式签名

正式版必须使用自己的签名文件。项目不会使用调试证书生成 release；缺少 `android/key.properties` 时，正式构建会主动停止。

### 1. 创建签名文件

在 Windows PowerShell 中运行：

```powershell
keytool -genkeypair -v -keystore "$env:USERPROFILE\upload-keystore.jks" -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

如果系统找不到 `keytool`，可以使用 Android Studio 自带版本，例如：

```powershell
& "F:\Android\Android Studio\jbr\bin\keytool.exe" -genkeypair -v -keystore "$env:USERPROFILE\upload-keystore.jks" -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

按提示在本机输入密码。不要把密码、`.jks` 文件或 `key.properties` 提交到 Git 或发给他人。

### 2. 创建签名配置

复制模板：

```powershell
Copy-Item android/key.properties.example android/key.properties
```

编辑 `android/key.properties`：

```properties
storePassword=你的签名库密码
keyPassword=你的密钥密码
keyAlias=upload
storeFile=C:/Users/你的用户名/upload-keystore.jks
```

`android/key.properties` 和所有 `.jks` 文件已被 `.gitignore` 排除。

## 打包

直接安装或分发 APK：

```powershell
flutter build apk --release
```

输出文件：

```text
build/app/outputs/flutter-apk/app-release.apk
```

发布 Google Play 的 AAB：

```powershell
flutter build appbundle --release
```

输出文件：

```text
build/app/outputs/bundle/release/app-release.aab
```

发布更新前必须递增 `pubspec.yaml` 中的版本号，例如：

```yaml
version: 1.0.1+2
```

请永久备份签名文件和密码。使用同一个包名发布后，后续版本必须使用兼容的签名才能覆盖安装和正常更新。

## 注意事项

- `com.zm.bill` 与早期测试包名 `com.example.bill` 会被手机视为两个不同的 App。
- 更换包名不会迁移旧测试版的应用内部数据，但 `Download/bill` 中的公共 TXT 会继续保留。
- 卸载 App 前建议确认公共 TXT 已正常生成。
- 不要把账目原因、金额、签名密码或私钥写入日志和代码仓库。
