# Naming conventions and best practices

> When to read: when naming things, organizing files, committing, or adding components.

## Naming
- Follow the language conventions that the linters enforce (Dart, Swift, Kotlin); they are not repeated here.
- Test naming: see `docs/testing.md`.

## Structure and organization
- Single repository with the Flutter project in the repo root. No backend, no monorepo split.
- Native widget code stays in `android/` and `ios/`. Dart code in `lib/` never imports native widget code.
- The only coupling between app and widgets is the widget-definition format and the shared storage keys. A change to either updates the Dart, Swift, and Kotlin sides and the fixtures in the same change.
- Shared InfluxDB response fixtures live in `fixtures/influx/` at the repo root and are loaded by all three test suites. Other shared contract fixtures: `fixtures/widget_definitions/`, `fixtures/formula/`, `fixtures/chart/`, `fixtures/alerts/`.

## Best practices (project-specific)
- Fixtures and docs contain only fake tokens and fake hostnames.
- Never log API tokens.

## Git
- Commit messages: Conventional Commits.
- Branches: commit directly to `main` for now (solo project).

---
Maintenance: update this file immediately when conventions change or new components are added.
