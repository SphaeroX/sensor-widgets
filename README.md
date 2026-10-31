# Sensor Widgets

[![CI](https://github.com/mgasc/InfluxDBWidget/actions/workflows/ci.yml/badge.svg)](https://github.com/mgasc/InfluxDBWidget/actions/workflows/ci.yml)
[![Build & Release APK](https://github.com/mgasc/InfluxDBWidget/actions/workflows/release.yml/badge.svg)](https://github.com/mgasc/InfluxDBWidget/actions/workflows/release.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**Sensor Widgets** is a privacy-first, open-source mobile app for Android and iOS that serves as a settings and configuration dashboard for native home-screen widgets directly querying InfluxDB.

Unlike generic widget frameworks that require the main app to run in the background, native widgets in **Sensor Widgets** query InfluxDB directly over its v1-compatible HTTP API (`/query`) using lightweight background execution (Android Jetpack Glance with WorkManager, and iOS WidgetKit with AppIntents).

---

## Features

### 6 Native Home-Screen Widget Types
1. **Single Value:** Displays the latest metric value with customizable decimal places, unit, and threshold-based status colors.
2. **History Chart:** Shows a smooth sparkline/area time-series trend line for selectable time windows (e.g. 1h, 6h, 24h, 7d, 30d).
3. **Indicator Lamp:** A clear status indicator lamp evaluating numeric thresholds (`>` or `<`) with glowing active/inactive colors.
4. **Gauge Bar:** A horizontal bar / gauge meter showing values relative to defined minimum and maximum bounds.
5. **Aggregate:** Displays summary metrics (`MIN`, `AVG` / `MEAN`, `MAX`) calculated over a given period.
6. **Multi Value:** Combines up to 3 different fields from the same measurement into a compact table.

### Configuration Dashboard
- **Connection Management:** Manage multiple InfluxDB instances (Cloud TSM, Cloud Serverless, self-hosted v1/v2/v3). Includes live connection testing.
- **Schema Discovery:** Automatically queries `SHOW MEASUREMENTS`, `SHOW FIELD KEYS`, `SHOW TAG KEYS`, and `SHOW TAG VALUES` for auto-complete assistance, with seamless manual free-text override.
- **Live Preview:** See real-time data previews in the widget editor before adding the widget to your home screen.
- **Home-Screen Binding:** Native selection activity (Android) and AppIntents `WidgetConfigurationIntent` with `EntityQuery` (iOS 17+) allowing direct widget assignment.

---

## Architecture & Security

```
+--------------------------------------------------------------+
|                    Flutter App (Dashboard)                   |
|  - Connection Manager (URL, Database, Token)                |
|  - Widget Configurator (Type, Measurement, Tags, Thresholds) |
+------------------------------+-------------------------------+
                               |
               Persists Config & Metadata
                               v
+--------------------------------------------------------------+
|                     Shared Storage Layer                     |
|  - Shared Prefs / App Group: widget_definitions_v1 (JSON)   |
|  - Shared Prefs / App Group: connections_metadata_v1 (JSON)  |
|  - Encrypted / Keychain:     influx_token_<id> (Secure)      |
+------------------------------+-------------------------------+
                               |
               Reads Config & Authenticates
                               v
+------------------------------+-------------------------------+
|         Android (Glance)     |        iOS (WidgetKit)        |
|  - WorkManager Background    |  - TimelineProvider           |
|  - Direct InfluxQL query     |  - Direct InfluxQL query      |
|  - Native Canvas & Sparkline |  - Swift Charts & SwiftUI     |
+------------------------------+-------------------------------+
                               |
                     HTTP GET /query?db=&q=
                               v
                  +--------------------------+
                  |    InfluxDB v1/v2/v3     |
                  +--------------------------+
```

### Privacy & Security Guarantee
- **No intermediary backend:** All network traffic travels directly between your device and your configured InfluxDB instance.
- **Secure Token Storage:** API tokens are stored securely in Android `EncryptedSharedPreferences` and iOS App Group Keychain (`kSecClassGenericPassword`).
- **Token Redaction:** All error handlers, query loggers, and exception types sanitize sensitive tokens with `***`.
- **Offline Resilience:** Native widgets cache the most recent reading in shared local storage (`widget_cache_<id>`) and display cached data gracefully during network dropouts.

---

## Building and Releases

### Prerequisites
- **Flutter:** 3.47.9+ (Dart 3.13.7+)
- **Java:** OpenJDK 17
- **Android SDK:** Compile SDK 36, Min SDK 26

### Local Development & Testing

```bash
# Get dependencies
flutter pub get

# Run all Flutter tests (unit, widget, E2E)
flutter test

# Run Android unit tests & ktlint
cd android
./gradlew test
./gradlew :app:ktlintCheck
cd ..

# Build release APK locally
flutter build apk --release
```

### GitHub Actions CI/CD
- **`ci.yml`:** Automatically tests Dart, runs Ktlint and Android JUnit tests, builds release APK check, and executes SwiftLint and Swift unit tests against shared fixtures on `macos-latest`.
- **`release.yml`:** Triggers when pushing a git tag (e.g. `git tag v1.0.0 && git push origin v1.0.0`) or manually via GitHub Actions workflow dispatch. Builds the production APK, calculates SHA-256 checksums, and attaches the APK directly to the GitHub Release.

---

## Documentation

Comprehensive project documentation is available in [`docs/`](docs/):
- [`docs/architecture.md`](docs/architecture.md) – Detailed architectural specifications and storage keys.
- [`docs/testing.md`](docs/testing.md) – Testing strategy across Dart, Kotlin, and Swift.
- [`docs/conventions.md`](docs/conventions.md) – Conventions for InfluxQL queries, JSON contracts, and fixtures.
- [`docs/code-style.md`](docs/code-style.md) – Formatting rules, linters, and style guidelines.
- [`docs/project-brief.md`](docs/project-brief.md) – Project vision and initial requirements.
- [`Roadmap/README.md`](Roadmap/README.md) – Sequential roadmap memory and task tracking.

---

## License

This project is licensed under the [MIT License](LICENSE).
