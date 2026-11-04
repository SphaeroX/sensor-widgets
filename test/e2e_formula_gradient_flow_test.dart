import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sensor_widgets/core/constants/storage_keys.dart';
import 'package:sensor_widgets/data/influx/influx_api_client.dart';
import 'package:sensor_widgets/data/storage/secure_token_store.dart';
import 'package:sensor_widgets/data/storage/shared_widget_store.dart';
import 'package:sensor_widgets/domain/models/influx_connection.dart';
import 'package:sensor_widgets/domain/models/influx_field_info.dart';
import 'package:sensor_widgets/domain/models/widget_definition.dart';
import 'package:sensor_widgets/domain/models/widget_type.dart';
import 'package:sensor_widgets/presentation/providers/storage_providers.dart';
import 'package:sensor_widgets/presentation/screens/dashboard/widgets_dashboard_screen.dart';
import 'package:sensor_widgets/presentation/widgets/editor/appearance_editor.dart';
import 'package:sensor_widgets/l10n/generated/app_localizations.dart';

class MockSharedWidgetStore extends Mock implements SharedWidgetStore {}

class MockSecureTokenStore extends Mock implements SecureTokenStore {}

class MockInfluxApiClient extends Mock implements InfluxApiClient {}

/// Milestone 4 end-to-end scenario: an IAQ history chart with formula,
/// time-bucket gap policy, value gradient and custom appearance, built purely
/// by tapping through the editor and verified in the bridge storage.
void main() {
  const conn = InfluxConnection(
    id: 'c1',
    name: 'Test Server',
    url: 'http://localhost:8086',
    database: 'sensors',
  );

  setUpAll(() {
    registerFallbackValue(conn);
    registerFallbackValue(
      const WidgetDefinition(
        id: 'dummy',
        type: WidgetType.singleValue,
        title: 'dummy',
        connectionId: 'c1',
        measurement: 'sen66',
      ),
    );
  });

  testWidgets('IAQ history chart: template, pickers, gradient, appearance', (
    tester,
  ) async {
    final shared = MockSharedWidgetStore();
    final tokens = MockSecureTokenStore();
    final api = MockInfluxApiClient();
    final store = <String, String>{
      StorageKeys.connectionsMetadataKey: jsonEncode([conn.toJson()]),
    };

    when(() => shared.getString(any()))
        .thenAnswer((inv) async => store[inv.positionalArguments[0] as String]);
    when(() => shared.saveString(any(), any())).thenAnswer((inv) async {
      store[inv.positionalArguments[0] as String] =
          inv.positionalArguments[1] as String;
    });
    when(() => shared.notifyWidgetsUpdated()).thenAnswer((_) async {});
    when(() => tokens.getToken('c1')).thenAnswer((_) async => 'token123');
    when(
      () => api.fetchMeasurements(
        connection: any(named: 'connection'),
        token: any(named: 'token'),
      ),
    ).thenAnswer((_) async => ['sen66']);
    when(
      () => api.fetchFieldInfos(
        connection: any(named: 'connection'),
        token: any(named: 'token'),
        measurement: any(named: 'measurement'),
      ),
    ).thenAnswer(
      (_) async => const [
        InfluxFieldInfo(key: 'co2', type: 'float'),
        InfluxFieldInfo(key: 'voc_index', type: 'float'),
        InfluxFieldInfo(key: 'pm2_5', type: 'float'),
        InfluxFieldInfo(key: 'humidity', type: 'float'),
      ],
    );
    when(
      () => api.fetchTagKeys(
        connection: any(named: 'connection'),
        token: any(named: 'token'),
        measurement: any(named: 'measurement'),
      ),
    ).thenAnswer((_) async => const []);

    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedWidgetStoreProvider.overrideWithValue(shared),
          secureTokenStoreProvider.overrideWithValue(tokens),
          influxApiClientProvider.overrideWithValue(api),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: WidgetsDashboardScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    Future<void> tapKey(String key) async {
      final finder = find.byKey(Key(key));
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    // --- Basics: title, history chart tile, measurement -------------------
    await tapKey('add_widget_fab');
    await tester.enterText(
      find.byKey(const Key('widget_title_field')),
      'IAQ Verlauf',
    );
    await tapKey('type_tile_history_chart');
    await tester.enterText(
      find.byKey(const Key('widget_measurement_field')),
      'sen66',
    );
    await tester.pumpAndSettle();

    // --- Formula from the IAQ template ------------------------------------
    await tapKey('formula_enabled_switch');
    await tapKey('formula_help_button');
    // The help screen is a lazy list: scroll to the template like a user would.
    await tester.scrollUntilVisible(
      find.byKey(const Key('apply_template_iaq_sen66')),
      300,
    );
    await tapKey('apply_template_iaq_sen66');
    expect(find.textContaining('Variablen zuordnen'), findsOneWidget);

    // --- Map the template variables via pickers (no typing of field names) -
    const mapping = {
      'co2': 'co2',
      'voc': 'voc_index',
      'pm25': 'pm2_5',
      'rh': 'humidity',
    };
    for (final entry in mapping.entries) {
      await tapKey('edit_variable_${entry.key}_button');
      await tester.tap(find.byKey(const Key('variable_field_input')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(entry.value).last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('apply_variable_button')));
      await tester.pumpAndSettle();
    }

    // --- Time buckets: carry the last value over gaps ----------------------
    await tapKey('gap_policy_previous');

    // --- Value gradient and area fill --------------------------------------
    await tapKey('preset_red_to_green');
    await tapKey('chart_fill_switch');

    // --- Appearance ---------------------------------------------------------
    await tapKey('palette_accent_3');

    // --- Save and inspect the bridge storage --------------------------------
    await tapKey('save_widget_button');
    expect(find.text('IAQ Verlauf'), findsOneWidget);

    final decoded = jsonDecode(store[StorageKeys.widgetDefinitionsKey]!);
    final widgets = decoded is List
        ? decoded
        : (decoded as Map<String, dynamic>)['widgets'] as List<dynamic>;
    expect(widgets, hasLength(1));
    final json = widgets.single as Map<String, dynamic>;

    expect(json['type'], 'history_chart');
    expect(json['formula'], 'min(s_co2, s_voc, s_pm25, s_rh)');
    expect((json['formulaSteps'] as List).map((s) => s['name']), [
      's_co2',
      's_voc',
      's_pm25',
      's_rh',
    ]);
    final variables = {
      for (final v in json['formulaVariables'] as List<dynamic>)
        v['name'] as String: v['field'] as String,
    };
    expect(variables, mapping);
    expect(json['gapPolicy'], 'previous');
    final style = json['chartStyle'] as Map<String, dynamic>;
    expect(style['fillArea'], isTrue);
    expect((style['colorStops'] as List).first['color'], '#F44336');
    expect(
      (json['appearance'] as Map<String, dynamic>)['accentColor'],
      AppearanceEditor.palette[3],
    );

    // The stored definition is valid and survives a roundtrip unchanged.
    final parsed = WidgetDefinition.fromJson(json);
    expect(parsed.isValid, isTrue);
    expect(parsed.toJson(), json);
  });
}
