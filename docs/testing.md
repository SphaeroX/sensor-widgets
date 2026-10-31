# Testing strategy

> When to read: before writing tests or changing test configuration.

## Test suites
- Dart/Flutter: `flutter_test` (unit and widget tests), `integration_test`, `mocktail` for mocks.
- iOS widget logic: XCTest or Swift Testing. Runs only in CI on macOS because there is no local Mac.
- Android widget logic: JUnit 4/5 with kotlinx-coroutines-test.

Reason: one standard suite per language, all runnable from the command line.

## TDD workflow (mandatory)
1. Red: write a test, run it, confirm it fails.
2. Green: write the minimal code until it passes.
3. Refactor: clean up; tests stay green.

## Commands

Verified in project environment:

```bash
flutter test                                                    # all Dart tests
flutter test test/path/to/file_test.dart                        # one file
flutter test --plain-name "<test name>"                         # one test
flutter test integration_test                                   # needs an emulator or device
cd android && ./gradlew test                                    # all Android unit tests
cd android && ./gradlew test --tests "<fully.qualified.Class>"  # one Android test class
cd android && ./gradlew :app:ktlintCheck                        # ktlint check
```

iOS (CI only via `macos-latest` runner):

```bash
swift test --package-path ios                                    # Swift unit tests against fixtures
xcodebuild test -workspace ios/Runner.xcworkspace -scheme <scheme> -destination 'platform=iOS Simulator,name=<device>'
```

Agents cannot run iOS tests locally. Push and read the GitHub Actions result.

## Which tests to run when
- Changes in `lib/`: the Dart tests of that area.
- Changes in `android/`: the Android unit tests.
- Changes in `ios/`: the iOS tests via CI.
- Changes to shared fixtures or the widget-definition format: all three suites.

## Done criteria
A task is done when all of this holds:
1. Tests of the affected area pass (commands above).
2. Format and lint are clean (commands in `docs/code-style.md`).
3. No existing test was changed, deleted, or weakened unless explicitly requested.

## Hard rules
- On a failing test, fix the implementation, not the test.
- At most 3 repair attempts per failing test; then stop and report.
- If an existing test must change: state the reason and wait for approval.

## Test structure
- Test types: unit and widget tests; integration tests only for core flows; native unit tests for query, parse, and threshold logic.
- Location: Dart tests in `test/` mirroring `lib/`; integration tests in `integration_test/`; native tests in the platform test targets.
- Naming: `<file>_test.dart`; Swift `<Type>Tests`; Kotlin `<Type>Test`.
- Test data: InfluxDB responses come from the shared fixtures (see `docs/conventions.md`). Automated tests never call a live InfluxDB.

---
Maintenance: update this file immediately when the testing suite or strategy changes.
