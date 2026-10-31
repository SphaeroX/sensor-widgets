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
- **Schema configuration:** Combined approach in the widget editor — schema discovery via InfluxQL (`SHOW MEASUREMENTS`, `SHOW FIELD KEYS`, `SHOW TAG KEYS`, `SHOW TAG VALUES`) with a seamless fallback to free-text input.
- **API token storage:** Tokens are stored in `EncryptedSharedPreferences` (Android) and the App Group Keychain (iOS `group.io.github.mgasc.influx_sensor_widgets`) via `flutter_secure_storage`; connection metadata and widget definitions (`schemaVersion: 1`) are stored as JSON in `home_widget` shared storage.
- **Shared Storage Keys (`lib/core/constants/storage_keys.dart`):**
  - App Group: `group.io.github.mgasc.influx_sensor_widgets`
  - Android Prefs: `sensor_widgets_prefs`
  - Widget Definitions Key: `widget_definitions_v1`
  - Connections Key: `connections_metadata_v1`
  - Token Prefix: `influx_token_<connectionId>`
  - Cache Prefix: `widget_cache_<widgetId>`
- **Widget Definitions Contract (`schemaVersion: 1`):**
  - Stored under `fixtures/widget_definitions/widget_definitions_v1.json` with 6 widget types: `single_value`, `history_chart`, `indicator_lamp`, `multi_value`, `aggregate`, `gauge_bar`.
  - Immutable models: `InfluxConnection`, `WidgetDefinition`, `ThresholdRule`, `SensorQueryItem`, `SensorDataPoint`.
- **iOS widget extension target:** Generated and verified reproducibly in GitHub Actions (`macos-latest`) via XcodeGen / project scripting (`Roadmap/Tasks/Task_09.md`).
- **Roadmap & task tracking:** Sequentially managed in `Roadmap/README.md` and `Roadmap/Tasks/Task_01.md` – `Task_10.md`.

---
Maintenance: update this file immediately when the stack or architecture changes.
