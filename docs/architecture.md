# Tech stack and architecture

> When to read: before structural changes, new components, or new dependencies.

## Tech stack
- **App:** Flutter 3.47.9 (Dart 3.13.7).
- **Core Dependencies (pinned in pubspec.yaml):**
  - `flutter_riverpod`: ^2.5.1 (installed 2.6.1)
  - `home_widget`: ^0.7.0 (installed 0.7.0+1)
  - `flutter_secure_storage`: ^9.2.2 (installed 9.2.4)
  - `http`: ^1.2.2 (installed 1.6.0)
  - `mocktail`: ^1.0.4 (installed 1.0.5)
  - `flutter_lints`: ^6.0.0
- **Android Target:** `minSdk 26`, `compileSdk 36`, target JVM 17. Application ID: `io.github.mgasc.influx_sensor_widgets`.
- **iOS Target:** iOS `17.0+`. Bundle ID: `io.github.mgasc.influx_sensor_widgets`.
- **Widgets:** SwiftUI + WidgetKit (iOS) and Kotlin + Jetpack Glance (Android). Flutter cannot draw home-screen widgets, so this layer is native.
- **App <-> widget data exchange:** `home_widget` plugin (shared storage: App Group `group.io.github.mgasc.influx_sensor_widgets` on iOS, SharedPreferences on Android).
- **Data source:** InfluxDB, queried with InfluxQL over the v1-compatible HTTP API (`/query` with `db`, `q`, and `Authorization: Token <token>`). Reason: the author's InfluxDB Cloud may be TSM (v2) or Serverless (v3), and InfluxQL is the common denominator; it also covers self-hosted v1/v2/v3. Flux and SQL are out of scope.

## Architecture
- The Flutter app is the settings dashboard only: it manages connections and widget definitions and writes them to shared storage.
- Native widgets read the definitions, query InfluxDB themselves in the background, and render natively. `HomeWidget.renderFlutterWidget` cannot be used for charts because it does not work while the app is fully in the background.
- Query and parse logic exists once per platform (Swift, Kotlin, plus Dart wherever the app itself talks to InfluxDB). The implementations are kept consistent by shared fixtures (see `docs/testing.md`) and one widget-definition format.
- iOS configuration: widgets are configured through AppIntents (`AppIntentConfiguration`, iOS 17+) with an `EntityQuery` that lists the definitions the app stored in the App Group.
- Values and the indicator lamp update on widget refresh only. No server and no push in v1.

## Platform limits that shape the design
- iOS: refreshes are budgeted by the system (roughly 40-70 background reloads per day for a frequently viewed widget). Network requests belong in the timeline provider, never in views.
- Android: `updatePeriodMillis` allows at most one update per 30 minutes; WorkManager allows about every 15 minutes.

## Environment
- Local Windows 11 environment with Flutter 3.47.9, Dart 3.13.7, OpenJDK 17, Android SDK 34/36.
- No local Mac or iPhone. iOS code is built (unsigned) and unit-tested in GitHub Actions on `macos-latest` runners.
- iOS code is never run on a local physical device. Do not describe iOS behavior as verified unless CI ran it.
- CI/CD workflows: `.github/workflows/ci.yml` (push/PR verification) and `.github/workflows/release.yml` (APK build and GitHub Release creation).

## Scaffolding Status
Scaffolding executed:
```bash
flutter create --project-name sensor_widgets --org io.github.mgasc --platforms android,ios .
```
Application / bundle ID configured to `io.github.mgasc.influx_sensor_widgets` across Android (`android/app/build.gradle.kts`) and iOS (`ios/Runner.xcodeproj/project.pbxproj`).

## Architectural decisions
- **State management & DI:** `flutter_riverpod` (`mocktail` for unit and widget tests).
- **Schema configuration:** Guided schema selection in the widget editor — automatic discovery via InfluxQL (`SHOW MEASUREMENTS`, `SHOW FIELD KEYS` including `fieldType`, `SHOW TAG KEYS`, `SHOW TAG VALUES`) presented via searchable bottom-sheet pickers, tag-filter chips, multi-field selection, explicit loading/error/reload feedback, and a manual free-text toggle fallback.
- **API token storage:** Tokens are stored in `EncryptedSharedPreferences` (Android) and the App Group Keychain (iOS `group.io.github.mgasc.influx_sensor_widgets`) via `flutter_secure_storage`; connection metadata and widget definitions (`schemaVersion: 1`) are stored as JSON in `home_widget` shared storage.
  - **Android Secure Storage:** `encryptedSharedPreferences: true` (accessed in native Kotlin via AndroidX Security `EncryptedSharedPreferences`).
  - **iOS Secure Storage:** App Group `group.io.github.mgasc.influx_sensor_widgets`, `kSecAttrAccessibleAfterFirstUnlock`.
  - **Token Key Format:** `influx_token_<connectionId>`.
- **Shared Storage Keys (`lib/core/constants/storage_keys.dart`):**
  - App Group: `group.io.github.mgasc.influx_sensor_widgets`
  - Android Prefs: `HomeWidgetPreferences` (primary, backed by `home_widget`) and `sensor_widgets_prefs` (fallback)
  - Widget Definitions Key: `widget_definitions_v1`
  - Connections Key: `connections_metadata_v1`
  - Token Prefix: `influx_token_<connectionId>`
  - Cache Prefix: `widget_cache_<widgetId>`
- **Widget Definitions Contract (`schemaVersion: 1`):**
  - Stored under `fixtures/widget_definitions/widget_definitions_v1.json` with 6 widget types: `single_value`, `history_chart`, `indicator_lamp`, `multi_value`, `aggregate`, `gauge_bar`.
  - Immutable models: `InfluxConnection`, `WidgetDefinition`, `ThresholdRule`, `SensorQueryItem`, `SensorDataPoint`, `FormulaVariable`.
  - Optional formula engine: `formula` (String arithmetic expression with operators `+`, `-`, `*`, `/`, unary minus, parentheses) and `formulaVariables` (mapping `A`, `B`, ... to InfluxDB fields, optional distinct measurements and tag filters).
- **Formula Engine & Cross-Platform Evaluator (Milestone 3):**
  - Evaluates formulas consistently across Dart (`FormulaEvaluator`), Android Kotlin (`FormulaEvaluator.kt`), and iOS Swift (`FormulaEvaluator.swift`).
  - Validated by shared fixtures in `fixtures/formula/evaluator_cases.json`.
  - Floating-point & average rounding: Arithmetic calculations and averages are consistently rounded to avoid IEEE-754 precision artifacts (e.g. `15.150000000000002` -> `15.15`). Decimal places are capped at a maximum of 2 digits across all platforms (`NumberFormatter` in Dart, `ChartMathAndFormatter` in Android, `WidgetViewHelpers` in iOS).
  - Query optimization: Variables sharing the same measurement and tags are fetched via a single InfluxQL query; distinct measurements/tags are fetched via parallel/sequential queries and joined locally.
  - Transparent error propagation: Division by zero, syntax errors, and missing measurement values produce explicit, user-visible error badges/messages rather than silent zero values.
- **Formula contract v2 (Milestone 4; Dart: Task_22, Kotlin and Swift: Task_23):**
  - Grammar (precedence low to high): comparison (`< > <= >= == !=`, result `1.0`/`0.0`, left-associative), `+ -`, `* /`, unary `-`, primary. No unary `+`, no `^` (use `pow`).
  - Functions: `min`/`max` (1..n args), `clamp(x, lo, hi)` (`lo > hi` is a domain error), `abs`, `pow`, `sqrt`, `ln`, `log10`, `exp`, `round` (half away from zero), `floor`, `ceil`, `if(cond, a, b)` (lazy: only the chosen branch is evaluated; non-zero is true). Constants `pi` and `e`; variables and steps with the same name win over constants.
  - `formulaSteps` (`[{name, expression, label?}]`, optional, `schemaVersion` stays 1): evaluated in order, each step sees variables and earlier steps only. `formula` is the final result expression and may use steps. Step names must be identifiers, unique, not equal to a variable name or a function name.
  - Stable error codes (`FormulaException.code`, used as `expected_error` in fixtures): `syntax_error`, `division_by_zero`, `missing_variable`, `unknown_function`, `wrong_arity`, `domain_error` (`sqrt(-1)`, `ln(0)`, `log10(<=0)`, non-finite `pow`/`exp`/arithmetic result), `step_reference_error` (forward/self reference, duplicate or reserved step name).
  - Fixtures: `fixtures/formula/evaluator_cases.json` keeps `valid_cases`/`error_cases` (v1, unchanged) and adds `v2_valid_cases`/`v2_error_cases` with optional `steps`. Dart, Kotlin (`FormulaEvaluatorV2Test`) and Swift (`FormulaEvaluatorV2Tests`) run both sections. Kotlin and Swift expose the same error codes (`FormulaException.code` / `FormulaError.code`), the same API (`evaluate(..., steps)`, `validateSyntax`, `validateSteps`, `extractVariables`) and parse `formulaSteps` (`FormulaStep` in `model/` resp. `WidgetModels.swift`). Widget fixture with steps: `fixtures/widget_definitions/widget_definition_formula_steps.json`. Native refresh paths (`WidgetRefreshWorker`, `SensorTimelineProvider`) pass `formulaSteps` to the evaluator. Swift is only verified once the GitHub Actions run is green.
  - API: `FormulaEvaluator.evaluate(formula, vars, steps:)`, `validateSyntax` (message includes 1-based `Position N`), `validateSteps(steps, formula, variableNames:)`, `extractVariables` (skips functions and `pi`/`e`). `WidgetDefinition.isValid` validates formula and steps.
- **iOS widget extension target:** Implemented in `ios/SensorWidgetsExtension/` using Swift 5.9+, SwiftUI, Swift Charts (`Charts`), and AppIntents (`SelectWidgetIntent`, `SensorTimelineProvider`, `SensorWidgetViews`). Configured with `ios/Package.swift` and verified in GitHub Actions (`macos-latest`) via `swift test --package-path ios` (`Roadmap/Archiv/Task_09.md`).
- **Roadmap & task tracking:** Sequentially managed in `Roadmap/README.md`, `Roadmap/Archiv/Task_01.md` – `Task_10.md` (Milestone 1), `Roadmap/Archiv/Task_11.md` – `Task_15.md` (Milestone 2: Guided Schema Selection UX), and `Roadmap/Archiv/Task_16.md` – `Task_20.md` (Milestone 3: Local Formula Calculation).

---
Maintenance: update this file immediately when the stack or architecture changes.
