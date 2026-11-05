import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_widgets/core/constants/storage_keys.dart';
import 'package:sensor_widgets/core/theme/app_theme.dart';
import 'package:sensor_widgets/data/influx/influx_api_client.dart';
import 'package:sensor_widgets/data/storage/secure_token_store.dart';
import 'package:sensor_widgets/data/storage/shared_widget_store.dart';
import 'package:sensor_widgets/domain/models/influx_connection.dart';
import 'package:sensor_widgets/domain/models/influx_field_info.dart';
import 'package:sensor_widgets/domain/models/widget_definition.dart';
import 'package:sensor_widgets/presentation/providers/storage_providers.dart';
import 'package:sensor_widgets/l10n/generated/app_localizations.dart';

/// Logical phone size of the README screenshots (rendered at [screenshotPixelRatio]).
const screenshotLogicalSize = Size(390, 844);
const screenshotPixelRatio = 2.0;

/// Demo connection shown in every screenshot (no real server is contacted).
const demoConnection = InfluxConnection(
  id: 'demo',
  name: 'Home Lab',
  url: 'https://influx.example.com',
  database: 'sensors',
);

/// Loads Roboto and the Material icons from the Flutter SDK, so text is readable
/// instead of the Ahem boxes `flutter_test` uses by default.
Future<void> loadScreenshotFonts() async {
  final fontsDir = _materialFontsDir();
  // flutter_test has no system fonts: Roboto also stands in for "monospace".
  for (final family in ['Roboto', 'monospace']) {
    final loader = FontLoader(family);
    for (final name in [
      'roboto-regular.ttf',
      'roboto-medium.ttf',
      'roboto-bold.ttf',
      'roboto-light.ttf',
    ]) {
      loader.addFont(_fontBytes(_fontFile(fontsDir, name)));
    }
    await loader.load();
  }

  final icons = FontLoader('MaterialIcons')
    ..addFont(_fontBytes(_fontFile(fontsDir, 'materialicons-regular.otf')));
  await icons.load();
}

/// The SDK names the files `Roboto-Regular.ttf` etc.; match case-insensitively
/// because Linux (CI) has a case-sensitive file system and Windows does not.
File _fontFile(Directory dir, String lowerCaseName) =>
    dir.listSync().whereType<File>().firstWhere(
      (f) => f.uri.pathSegments.last.toLowerCase() == lowerCaseName,
      orElse: () => throw StateError('$lowerCaseName not in ${dir.path}'),
    );

Future<ByteData> _fontBytes(File file) async =>
    ByteData.sublistView(await file.readAsBytes());

Directory _materialFontsDir() {
  final candidates = <String>[?Platform.environment['FLUTTER_ROOT']];
  // flutter_tester lives in <flutter>/bin/cache/artifacts/engine/<platform>/.
  var dir = File(Platform.resolvedExecutable).parent;
  for (var i = 0; i < 8; i++) {
    candidates.add(dir.path);
    dir = dir.parent;
  }
  for (final root in candidates) {
    final fonts = Directory('$root/bin/cache/artifacts/material_fonts');
    if (fonts.existsSync()) return fonts;
  }
  throw StateError('Flutter material_fonts not found (set FLUTTER_ROOT).');
}

/// Sets the test view to a phone screen and resets it after the test.
void usePhoneScreen(WidgetTester tester) {
  tester.view.physicalSize = screenshotLogicalSize * screenshotPixelRatio;
  tester.view.devicePixelRatio = screenshotPixelRatio;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

/// In-memory bridge storage pre-filled with the demo connection and [widgets].
class FakeSharedWidgetStore implements SharedWidgetStore {
  final Map<String, String> values = {};

  FakeSharedWidgetStore({List<WidgetDefinition> widgets = const []}) {
    values[StorageKeys.connectionsMetadataKey] = jsonEncode([
      demoConnection.toJson(),
    ]);
    if (widgets.isNotEmpty) {
      values[StorageKeys.widgetDefinitionsKey] = jsonEncode({
        'schemaVersion': StorageKeys.schemaVersion,
        'widgets': widgets.map((w) => w.toJson()).toList(),
      });
    }
  }

  @override
  Future<String?> getString(String key) async => values[key];

  @override
  Future<void> saveString(String key, String value) async =>
      values[key] = value;

  @override
  Future<void> notifyWidgetsUpdated() async {}
}

class FakeSecureTokenStore implements SecureTokenStore {
  @override
  Future<String?> getToken(String connectionId) async => 'demo-token';

  @override
  Future<bool> hasToken(String connectionId) async => true;

  @override
  Future<void> saveToken(String connectionId, String token) async {}

  @override
  Future<void> deleteToken(String connectionId) async {}
}

/// Answers schema queries and InfluxQL with deterministic demo data shaped like
/// an indoor air sensor (SEN66), so previews show realistic curves and values.
class FakeInfluxApiClient implements InfluxApiClient {
  static const fields = {
    'co2': 812.0,
    'temperature': 22.4,
    'humidity': 46.0,
    'voc_index': 118.0,
    'nox_index': 1.0,
    'pm2_5': 4.2,
  };

  @override
  Future<List<String>> fetchMeasurements({
    required InfluxConnection connection,
    required String token,
  }) async => ['sen66', 'outdoor'];

  @override
  Future<List<InfluxFieldInfo>> fetchFieldInfos({
    required InfluxConnection connection,
    required String token,
    required String measurement,
  }) async => [
    for (final f in fields.keys) InfluxFieldInfo(key: f, type: 'float'),
  ];

  @override
  Future<List<String>> fetchFieldKeys({
    required InfluxConnection connection,
    required String token,
    required String measurement,
  }) async => fields.keys.toList();

  @override
  Future<List<String>> fetchTagKeys({
    required InfluxConnection connection,
    required String token,
    required String measurement,
  }) async => ['room'];

  @override
  Future<List<String>> fetchTagValues({
    required InfluxConnection connection,
    required String token,
    required String measurement,
    required String tagKey,
  }) async => ['living_room', 'office'];

  @override
  Future<bool> testConnection({
    required InfluxConnection connection,
    required String token,
  }) async => true;

  @override
  Future<Map<String, dynamic>> query({
    required InfluxConnection connection,
    required String token,
    required String influxQl,
  }) async {
    final select = influxQl.substring(0, influxQl.indexOf(' FROM '));
    final aliases = RegExp(r'AS "([^"]+)"')
        .allMatches(select)
        .map((m) => m.group(1)!)
        .toList();
    final columns = aliases.isNotEmpty
        ? aliases
        : RegExp(r'"([^"]+)"')
              .allMatches(select)
              .map((m) => m.group(1)!)
              .toList();
    final end = DateTime.utc(2026, 11, 3, 14).millisecondsSinceEpoch;
    final bucketed = influxQl.contains('GROUP BY time');
    final rows = bucketed ? 48 : 1;

    final values = [
      for (var i = 0; i < rows; i++)
        [
          end - (rows - 1 - i) * 30 * 60 * 1000,
          for (final c in columns) _demoValue(c, i, rows),
        ],
    ];
    return {
      'results': [
        {
          'statement_id': 0,
          'series': [
            {
              'name': 'sen66',
              'columns': ['time', ...columns],
              'values': values,
            },
          ],
        },
      ],
    };
  }

  double _demoValue(String column, int i, int rows) {
    final base = switch (column) {
      'min' => 640.0,
      'max' => 1180.0,
      'mean' => 812.0,
      _ => fields[column] ?? 50.0,
    };
    if (rows == 1) return base;
    final t = i / (rows - 1);
    final wave = math.sin(t * math.pi * 2.2) * 0.25 + math.sin(t * 9) * 0.05;
    return double.parse((base * (1 + wave)).toStringAsFixed(1));
  }
}

/// The app's dark theme around [home], with all storage and network faked.
Widget screenshotApp({required Widget home, List<WidgetDefinition>? widgets}) {
  return ProviderScope(
    overrides: [
      sharedWidgetStoreProvider.overrideWithValue(
        FakeSharedWidgetStore(widgets: widgets ?? const []),
      ),
      secureTokenStoreProvider.overrideWithValue(FakeSecureTokenStore()),
      influxApiClientProvider.overrideWithValue(FakeInfluxApiClient()),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: home,
    ),
  );
}

/// Taps the widget with [key] after scrolling it into view.
Future<void> tapKey(WidgetTester tester, String key) async {
  final finder = find.byKey(Key(key));
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Writes the whole screen to `docs/screenshots/<name>.png`.
Future<void> captureScreen(String name) async {
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('../docs/screenshots/$name.png'),
  );
}

/// Golden comparator that only writes images: screenshots are regenerated on demand,
/// never compared (font rendering differs between machines).
class WriteOnlyGoldenComparator extends LocalFileComparator {
  WriteOnlyGoldenComparator(super.testFile);

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    await update(golden, imageBytes);
    return true;
  }
}
