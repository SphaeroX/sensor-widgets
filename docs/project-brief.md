# Project brief

> When to read: when the goal, scope, or boundaries of the project are unclear.

## Goal and audience
Working title: `sensor-widgets`. A mobile app for Android and iOS that serves as the settings dashboard for many home-screen widgets showing InfluxDB data (for example current temperature, temperature history, room and sensor data). Audience: the author and the open-source community. Public GitHub repository, MIT license.

## Core features
- Widget types: single value (with unit and timestamp), history chart (selectable time range), indicator lamp that switches at a threshold (greater or less than), multi-value overview (e.g. a room with several sensors), aggregate over a time range (min, max, average), gauge or bar.
- Local formula calculation for every widget type and every multi-value row: arithmetic expressions combining multiple InfluxDB fields/measurements (`+ - * /`, comparisons, `if`, functions such as `min`, `max`, `clamp`, `pow`, `sqrt`, `ln`, constants `pi`/`e`) with named intermediate steps. Variables are picked from the database schema. History charts and aggregates are calculated per time bucket with a configurable gap policy. An in-app help page with templates (e.g. IAQ for the Sensirion SEN66) explains the language.
- Per-widget configuration: connection, measurement, field, formula, filter, time range, unit, colors, thresholds, value gradient for history charts (color stops, area fill, grid, axes, min/max markers) and appearance (background color and opacity, text and accent color, font scale, corner radius).
- Widgets fetch their data themselves in the background and refresh on the platform schedule (about every 15-30 minutes).
- Many widgets can be created and managed from the app.

## Non-goals
- Writing data to InfluxDB (the app is read-only).
- Managing InfluxDB (buckets, tokens, organizations).
- Own server and server push (APNs/FCM). Local threshold notifications from the widget refresh are in scope (`alerts`, see `docs/architecture.md`).
- Web or desktop version.

## Constraints
- Data source: InfluxDB Cloud (variant unknown: TSM or Serverless), queried with InfluxQL via the v1-compatible API; self-hosted instances should work too.
- No own server: the app talks directly to the user's InfluxDB.
- Android is tested on a real device. iOS is only built and unit-tested in GitHub Actions (no Mac, iPhone, or Apple Developer account).
- Public GitHub repository, MIT license. Store release is optional and may be done by someone else.
- Name: avoid "Influx" or "InfluxDB" in the app name and store listing (InfluxData trademark; not legal advice).

## Decisions & status
- Display title: `Sensor Widgets`, Android package: `io.github.sphaerox.influx_sensor_widgets`, iOS bundle ID: `io.github.mgasc.influx_sensor_widgets`.
- Technical decisions: see `docs/architecture.md`.
- Implementation roadmap: see `Roadmap/README.md` (milestones 1 to 4 implemented; `Task_21`, a dashboard layout bug, could not be reproduced and is covered by regression tests only).
- Store release remains optional and may be done later.

---
Maintenance: update this file when goals or scope change.
