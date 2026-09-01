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
