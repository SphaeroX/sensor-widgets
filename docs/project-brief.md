# Project brief

> When to read: when the goal, scope, or boundaries of the project are unclear.

## Goal and audience
Working title: `sensor-widgets`. A mobile app for Android and iOS that serves as the settings dashboard for many home-screen widgets showing InfluxDB data (for example current temperature, temperature history, room and sensor data). Audience: the author and the open-source community. Public GitHub repository, MIT license.

## Core features
- Widget types: single value (with unit and timestamp), history chart (selectable time range), indicator lamp that switches at a threshold (greater or less than), multi-value overview (e.g. a room with several sensors), aggregate over a time range (min, max, average), gauge or bar.
- Per-widget configuration: connection, measurement, field, filter, time range, unit, colors, thresholds.
- Widgets fetch their data themselves in the background and refresh on the platform schedule (about every 15-30 minutes).
- Many widgets can be created and managed from the app.

## Non-goals
- Writing data to InfluxDB (the app is read-only).
- Managing InfluxDB (buckets, tokens, organizations).
- Own server and push notifications in v1.
- Web or desktop version.

## Constraints
- Data source: InfluxDB Cloud (variant unknown: TSM or Serverless), queried with InfluxQL via the v1-compatible API; self-hosted instances should work too.
- No own server: the app talks directly to the user's InfluxDB.
- Android is tested on a real device. iOS is only built and unit-tested in GitHub Actions (no Mac, iPhone, or Apple Developer account).
- Public GitHub repository, MIT license. Store release is optional and may be done by someone else.
- Name: avoid "Influx" or "InfluxDB" in the app name and store listing (InfluxData trademark; not legal advice).

## Decisions & status
- Display title: `Sensor Widgets`, package/bundle ID: `io.github.mgasc.influx_sensor_widgets`.
- Technical decisions: see `docs/architecture.md`.
- Implementation roadmap: see `Roadmap/README.md` (`Task_01` – `Task_10`).
- Store release remains optional and may be done later.

---
Maintenance: update this file when goals or scope change.
