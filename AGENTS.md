# Project instructions

Before making any code or UI change, read `DEVELOPMENT_GUIDE.md` completely and follow it.

Project invariants:

- Preserve existing ledger data, TXT formatting, and Android public export behavior.
- Keep every tool in its own `lib/tools/<tool_name>/` folder and register it once in `lib/tools/tool_registry.dart`.
- Keep the main navigation limited to 首页、分类、收藏、设置.
- Obtain user approval for new or materially changed UI before implementation.
- Prefer offline, low-permission, local processing; never embed API secrets in the app.
- Add meaningful Chinese comments around business rules, compatibility, and security boundaries.
- Run formatting, static analysis, tests, and relevant release builds in the order defined by `DEVELOPMENT_GUIDE.md`.

## Existing tool inventory and duplicate prevention

Before proposing, designing, or implementing any tool, the agent must inspect both this inventory and `lib/tools/tool_registry.dart`. The registry is the source of truth. A different name, icon, category, or screen layout does not make substantially identical functionality a new tool.

Current tools:

| Stable ID | Name | Existing functional scope |
|---|---|---|
| `expense` | 收支账本 | Record income and expenses, categorize entries, calculate monthly totals, manage multiple monthly TXT files, and sync public TXT copies by year. |
| `calculator` | 计算器 | Safe basic addition, subtraction, multiplication, and division without evaluating code. |
| `unit_converter` | 单位换算 | Convert length, weight, and temperature units. Extend this tool instead of creating another general unit converter. |
| `date_calculator` | 日期计算 | Calculate the interval between dates and add or subtract days from a date. |
| `password_generator` | 密码生成 | Generate offline passwords with a cryptographically secure random source and selectable character groups. |
| `text_tools` | 文本工具 | Count characters, words, and lines; convert letter case; trim lines; remove blank lines; encode and strictly decode bounded HTML entities. General text transforms belong here when they do not need a separate workflow. |
| `qr_code` | 二维码 | Generate a QR code locally from text or a URL. |
| `bmi_calculator` | BMI 计算 | Calculate BMI from height and weight and show the corresponding range. |
| `stopwatch_timer` | 秒表与倒计时 | Stopwatch, lap recording, and countdown timer. |
| `percentage_calculator` | 百分比计算 | Calculate ratios, percentage increases/decreases, and discounts. |
| `bill_split` | AA 分摊 | Split a total amount and additional fees among a specified number of people. |
| `age_calculator` | 年龄计算 | Calculate age, days lived, next birthday, and birthday countdown. |
| `random_decision` | 随机决定 | Generate random integers and perform dice, coin, and option-drawing decisions. |
| `tally_counter` | 计数器 | Create and persist multiple independent increment/decrement counters. |
| `text_diff` | 文本对比 | Compare two texts line by line and show added, removed, and unchanged lines. |
| `list_processor` | 列表处理 | Parse, sort, deduplicate, shuffle, and clean line- or comma-separated lists. |
| `json_tool` | JSON工具 | Format, minify, and validate JSON locally with bounded input size and safe parse errors. |
| `base64_tool` | Base64 | Encode and decode bounded UTF-8 text locally; it does not treat input as a file or executable content. |
| `url_tool` | URL 编解码 | Encode and decode URI components and parse repeated query parameters locally without opening or requesting URLs. |
| `timestamp_converter` | Unix 时间戳 | Convert bounded Unix seconds or milliseconds to local dates and convert supported local dates back to timestamps. |
| `number_base_converter` | 进制转换 | Convert signed arbitrary-precision integers among binary, octal, decimal, and hexadecimal with bounded input. |
| `uuid_generator` | UUID 生成 | Generate bounded batches of UUID v4 values with the platform cryptographically secure random source; results remain in memory. |
| `regex_tester` | 正则测试 | Test bounded regular expressions in a killable background isolate with timeout protection and bounded match output. |
| `hash_generator` | 哈希生成 | Generate bounded UTF-8 text digests, SHA-256/SHA-512 HMAC values, or stream a user-selected Android file up to 512 MB through the system document picker for MD5/SHA verification; never upload, modify, log, or persist file content, keys, or paths. |
| `color_contrast` | 颜色与对比度 | Parse bounded HEX colors and calculate WCAG contrast ratios and AA/AAA thresholds locally. |
| `jwt_viewer` | JWT 查看 | Decode bounded JWT Header and Payload JSON locally, display expiry hints, and explicitly never claim signature validity. |
| `csv_json_converter` | CSV/JSON 转换 | Convert bounded RFC-4180-style CSV tables and flat JSON object arrays locally with row, column, and output limits. |
| `cron_parser` | Cron 解析 | Parse bounded standard five-field Cron expressions offline and calculate five future runs in the device local timezone. |
| `placeholder_text` | 占位文本 | Generate bounded Chinese or Latin layout samples by paragraph and sentence counts; no text editing or persistence. |
| `ipv4_subnet` | IPv4 子网计算 | Calculate IPv4 network, mask, broadcast and usable range from CIDR, including /31 and /32; never scan or enumerate hosts. |
| `chmod_calculator` | 权限计算 | Convert three-digit octal Unix permissions and nine read/write/execute checkboxes; no special bits, commands or file changes. |
| `luhn_checker` | Luhn 校验 | Validate bounded ASCII digit sequences or append a Luhn check digit; never claim real-world validity or persist numbers. |
| `markdown_preview` | Markdown 预览 | Render a bounded safe Markdown subset locally; never execute HTML or scripts, load remote resources, or automatically open links. |
| `http_status_reference` | HTTP 状态码 | Search an offline catalog of common HTTP status meanings, scenarios and handling advice; never send HTTP requests. |
| `mime_type_reference` | MIME 类型 | Query a bounded built-in extension-to-MIME table in either direction; never read or sniff files. |
| `image_optimizer` | 图片优化 | Select one JPEG/PNG/WebP image through Android's system picker, enforce 20 MB and 24-megapixel limits, resize/compress it off the UI thread, remove metadata by re-encoding, and explicitly save a result to the public Pictures directory. Never upload images or move image bytes through Dart. |
| `aspect_ratio_calculator` | 宽高比计算 | Reduce integer dimensions to a ratio and calculate bounded aspect-preserving target dimensions locally. |
| `yaml_json_converter` | YAML/JSON 转换 | Convert bounded YAML and JSON documents locally with node, depth, input, and output limits; only JSON-compatible values and string mapping keys are accepted. |
| `xml_tool` | XML 工具 | Format, minify, and validate bounded XML locally while rejecting DTD and entity declarations and enforcing node, depth, input, and output limits. |
| `unicode_inspector` | Unicode 检查 | Inspect bounded text by Unicode scalar and show code points, UTF-8, UTF-16, and escape forms; it does not identify fonts, languages, or confusable characters. |
| `port_reference` | 端口号参考 | Search a bounded built-in table of common TCP/UDP ports by number or service name; never scan networks, open sockets, or claim live port usage. |
| `totp_generator` | TOTP 验证码 | Generate bounded RFC 6238 TOTP codes from a manually entered Base32 secret using SHA-1/SHA-256/SHA-512, 6/8 digits and 30/60-second periods; secrets and codes are transient and never persisted or logged. |
| `ohms_law_calculator` | 欧姆定律 | Calculate voltage, current, resistance and power from any two positive bounded electrical quantities with common SI input units. |
| `statistics_calculator` | 统计计算 | Parse up to 10,000 bounded finite numbers and calculate descriptive statistics including mean, median, range, and population/sample standard deviation. |
| `roman_numeral_converter` | 罗马数字 | Strictly convert decimal integers from 1 to 3999 and canonical Roman numerals in both directions. |

Duplicate decisions already established:

- Do not add another word counter, case converter, blank-line cleaner, or basic text statistics tool; extend `text_tools` when appropriate.
- Do not add another list sorter, deduplicator, random list shuffler, or list cleaner; extend `list_processor`.
- Do not add another text comparison or Git-style line diff screen; extend `text_diff`.
- Do not add another basic QR generator, password generator, random picker, stopwatch, countdown, unit converter, percentage calculator, bill splitter, age calculator, or ledger under a different name.
- A specialized calculator may remain separate only when it has a clearly different input model and user workflow, as with BMI, percentage, age, date, and bill splitting.

Candidate tools checked against the current inventory:

- Now covered: Chinese/Latin placeholder text, IPv4 CIDR calculation, ordinary Unix permission calculation and Luhn checking; extend their existing modules instead of adding duplicates.
- Now covered: file-hash verification extends `hash_generator`; Markdown preview, offline HTTP status reference and MIME type reference each use their dedicated workflow. Extend these modules instead of adding duplicates.
- Now covered: image resize/compression belongs to `image_optimizer`; aspect-ratio reduction and dimension scaling belong to `aspect_ratio_calculator`. Extend these modules instead of adding duplicates.
- Now covered: HMAC belongs to `hash_generator`, and HTML entity conversion belongs to `text_tools`; extend those modules instead of adding duplicates.
- Now covered: YAML/JSON conversion, bounded XML processing, Unicode scalar inspection, and offline common-port lookup each use their dedicated modules. Extend these modules instead of adding duplicates.
- Now covered: RFC 6238 TOTP generation, four-value Ohm's-law solving, bounded descriptive statistics, and canonical Roman numeral conversion each use their dedicated modules. Extend these modules instead of adding duplicates.
- Do not add a separate OTP authenticator or TOTP screen under another name; account persistence, QR import, HOTP, and backup workflows require a separate security and UI review before extending `totp_generator`.
- Do not add another mean, median, range, variance, or standard-deviation calculator; extend `statistics_calculator`.
- Electrical formula solving belongs to `ohms_law_calculator`, while conversions between units of the same quantity belong to `unit_converter`.
- Roman numerals belong to `roman_numeral_converter`; positional binary/octal/decimal/hexadecimal conversion remains in `number_base_converter`.
- Do not add a separate ASCII table; ASCII inspection is a filter inside `unicode_inspector`.
- JSONPath or other general JSON queries should extend `json_tool` instead of creating another JSON workbench.
- Already covered: text case conversion, word/character/line counting, list sorting/deduplication/shuffling, text diff, QR generation, password generation, general unit conversion, and random selection.
- Partially covered: advanced text-case formats should normally extend `text_tools`; additional physical units should extend `unit_converter`; random-string generation should be evaluated against `password_generator` before becoming separate.

Mandatory process for adding a tool:

1. Compare the requested behavior—not only its title—with every row above and with the registry.
2. If at least half of its primary operations already exist in one tool, prefer extending that tool unless the user explicitly approves a separate workflow.
3. Confirm the stable ID is new and the title does not create a misleading duplicate.
4. Obtain approval for the UI design when a new page or material UI change is required.
5. Implement the tool in its own `lib/tools/<tool_name>/` directory and register it exactly once.
6. Update this inventory in the same change that adds, removes, renames, or materially expands a tool. A tool change is incomplete while this inventory and the registry disagree.
