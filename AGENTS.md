# sensor-widgets

Flutter app (Android and iOS) that acts as the settings dashboard for home-screen widgets showing InfluxDB data. The widgets themselves are native (SwiftUI/WidgetKit, Kotlin/Jetpack Glance). Open source (MIT), no backend.

## Top rules

1. **Test-driven development is mandatory.** Always write a failing test first (Red), then the minimal code (Green), then refactor. Suites: `flutter_test` with `mocktail` (Dart), XCTest or Swift Testing (iOS widgets), JUnit (Android widgets). No production code without a prior failing test. Bug fixes start with a test that reproduces the bug.
   - Never change, delete, or weaken an existing test to get green. Fix the implementation. If the test itself is wrong, explain why and ask for approval.
   - Repair budget: at most 3 attempts per failing test, then stop and report (which tests, what was tried, suspected cause).
   - Run the tests that belong to your change first (commands in `docs/testing.md`); run the full suite only when shared code changes.
2. **Keep the docs current.** If the stack, architecture, conventions, code style, or testing change, update the matching file in `docs/` in the same step. A task is done only when `docs/` is accurate.
3. **Use only the project toolchain.** `flutter pub` for Dart dependencies, Gradle for Android, the Flutter version pinned at scaffolding (see `docs/architecture.md`). No other package managers.
4. **iOS cannot be run locally.** There is no Mac or iPhone. iOS tests run only in GitHub Actions. Never claim iOS code works unless CI ran it, and never assume an unverified command worked.

## Commands

Verified locally (Windows 11, Flutter 3.47.9 / Dart 3.13.7, OpenJDK 17, Android SDK 34):

```bash
flutter pub get
flutter test
flutter test test/path/to/file_test.dart
flutter analyze
dart format --set-exit-if-changed .
cd android && ./gradlew test
cd android && ./gradlew :app:ktlintCheck
```

Integration tests and iOS: `docs/testing.md`. Lint and format details: `docs/code-style.md`.

## Docs (load on demand)

Read only what your current task needs:

- [docs/architecture.md](docs/architecture.md) - Read before structural changes, new components, or new dependencies. Tech stack, architecture, platform limits, open decisions.
- [docs/testing.md](docs/testing.md) - Read before writing tests or changing test configuration. Testing strategy and suites.
- [docs/code-style.md](docs/code-style.md) - Read before writing or formatting code. Formatter and linter setup.
- [docs/conventions.md](docs/conventions.md) - Read when naming, organizing files, or committing. Conventions and best practices.
- [docs/project-brief.md](docs/project-brief.md) - Read when goal, scope, or non-goals are unclear. Widget catalogue and constraints.

## Boundaries

- The repository is public: never commit tokens, signing material, or real InfluxDB data.
- No new dependencies without asking.
- Do not change the widget-definition format or the shared storage keys without updating the Dart, Swift, and Kotlin sides and the fixtures in the same change.
