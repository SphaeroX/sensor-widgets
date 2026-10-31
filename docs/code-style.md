# Code style and formatting

> When to read: before writing, changing, or formatting code.

## Tools
- Dart: `dart format` (formatter) and `flutter analyze` (linter). The rules live in `analysis_options.yaml`, configured with strict analyzer options.
- Swift: SwiftLint, configured in `.swiftlint.yml`. Runs on macOS or in CI only (`swiftlint --strict`).
- Kotlin: ktlint; formatting rules come from `.editorconfig` with `ktlintCheck` and `ktlintFormat` Gradle tasks.

## Mandatory commands

Verified in project environment:

```bash
dart format --set-exit-if-changed .
flutter analyze
cd android && ./gradlew :app:ktlintCheck
cd android && ./gradlew :app:ktlintFormat       # auto-fix formatting
swiftlint                                       # macOS or CI only
```

- Code counts as done only when these pass.
- Indentation and line endings come from `.editorconfig`; do not override them per file.

---
Maintenance: update this file immediately when style or tool rules change.
