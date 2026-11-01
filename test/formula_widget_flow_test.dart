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
import 'package:sensor_widgets/domain/models/widget_definition.dart';
import 'package:sensor_widgets/domain/models/widget_type.dart';
import 'package:sensor_widgets/presentation/providers/storage_providers.dart';
import 'package:sensor_widgets/presentation/screens/dashboard/widgets_dashboard_screen.dart';

class MockSharedWidgetStore extends Mock implements SharedWidgetStore {}

class MockSecureTokenStore extends Mock implements SecureTokenStore {}

class MockInfluxApiClient extends Mock implements InfluxApiClient {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      const InfluxConnection(
        id: 'c1',
        name: 'Test Server',
        url: 'http://localhost:8086',
        database: 'sensors',
      ),
    );
    registerFallbackValue(
      const WidgetDefinition(
        id: 'dummy',
        type: WidgetType.singleValue,
        title: 'dummy',
        connectionId: 'c1',
        measurement: 'climate',
      ),
    );
  });

  group('Formula Widget Flow Integration Test', () {
    late MockSharedWidgetStore mockSharedStore;
    late MockSecureTokenStore mockTokenStore;
    late MockInfluxApiClient mockApiClient;
    late Map<String, String> sharedStoreMap;

    setUp(() {
      mockSharedStore = MockSharedWidgetStore();
      mockTokenStore = MockSecureTokenStore();
      mockApiClient = MockInfluxApiClient();
      sharedStoreMap = {};

      const conn = InfluxConnection(
        id: 'c1',
        name: 'Test Server',
        url: 'http://localhost:8086',
        database: 'sensors',
      );

      sharedStoreMap[StorageKeys.connectionsMetadataKey] = jsonEncode([
        conn.toJson(),
      ]);

      when(() => mockSharedStore.getString(any())).thenAnswer(
        (inv) async => sharedStoreMap[inv.positionalArguments[0] as String],
      );
      when(() => mockSharedStore.saveString(any(), any()))
          .thenAnswer((inv) async {
            sharedStoreMap[inv.positionalArguments[0] as String] =
                inv.positionalArguments[1] as String;
          });
      when(() => mockSharedStore.notifyWidgetsUpdated())
          .thenAnswer((_) async {});

      when(() => mockTokenStore.getToken('c1'))
          .thenAnswer((_) async => 'token123');

      when(
        () => mockApiClient.fetchMeasurements(
          connection: any(named: 'connection'),
          token: any(named: 'token'),
        ),
      ).thenAnswer((_) async => ['climate']);

      when(
        () => mockApiClient.fetchFieldKeys(
          connection: any(named: 'connection'),
          token: any(named: 'token'),
          measurement: any(named: 'measurement'),
        ),
      ).thenAnswer((_) async => ['temp_in', 'temp_out']);

      when(
        () => mockApiClient.fetchTagKeys(
          connection: any(named: 'connection'),
          token: any(named: 'token'),
          measurement: any(named: 'measurement'),
        ),
      ).thenAnswer((_) async => ['location']);

      when(
        () => mockApiClient.query(
          connection: any(named: 'connection'),
          token: any(named: 'token'),
          influxQl: any(named: 'influxQl'),
        ),
      ).thenAnswer(
        (_) async => {
          'results': [
            {
              'statement_id': 0,
              'series': [
                {
                  'name': 'climate',
                  'columns': ['time', 'temp_in', 'temp_out'],
                  'values': [
                    [1730370000000, 20.0, 30.0],
                  ],
                },
              ],
            },
          ],
        },
      );
    });

    testWidgets('Full flow: add formula widget -> save -> verify stored JSON', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedWidgetStoreProvider.overrideWithValue(mockSharedStore),
            secureTokenStoreProvider.overrideWithValue(mockTokenStore),
            influxApiClientProvider.overrideWithValue(mockApiClient),
          ],
          child: const MaterialApp(home: WidgetsDashboardScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Tap FAB to add widget
      await tester.tap(find.byKey(const Key('add_widget_fab')));
      await tester.pumpAndSettle();

      expect(find.text('Widget konfigurieren'), findsOneWidget);

      // Enter Title
      await tester.enterText(
        find.byKey(const Key('widget_title_field')),
        'Temp Difference',
      );

      // Measurement
      await tester.enterText(
        find.byKey(const Key('widget_measurement_field')),
        'climate',
      );

      // Enable Formula
      await tester.ensureVisible(
        find.byKey(const Key('formula_enabled_switch')),
      );
      await tester.tap(find.byKey(const Key('formula_enabled_switch')));
      await tester.pumpAndSettle();

      // Enter Formula
      await tester.enterText(
        find.byKey(const Key('formula_input_field')),
        'A - B',
      );

      // Edit default Variable A
      await tester.tap(find.byKey(const Key('edit_variable_A_button')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('variable_field_input')),
        'temp_out',
      );
      await tester.tap(find.byKey(const Key('apply_variable_button')));
      await tester.pumpAndSettle();

      // Add Variable B
      await tester.tap(find.byKey(const Key('add_formula_variable_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('edit_variable_B_button')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('variable_field_input')),
        'temp_in',
      );
      await tester.tap(find.byKey(const Key('apply_variable_button')));
      await tester.pumpAndSettle();

      // Unit
      await tester.enterText(find.byKey(const Key('widget_unit_field')), '°C');

      // Save
      await tester.ensureVisible(find.byKey(const Key('save_widget_button')));
      await tester.tap(find.byKey(const Key('save_widget_button')));
      await tester.pumpAndSettle();

      // Verify widget appears on dashboard
      expect(find.text('Temp Difference'), findsOneWidget);

      // Verify saved widget in storage
      final rawWidgets = sharedStoreMap[StorageKeys.widgetDefinitionsKey];
      expect(rawWidgets, isNotNull);

      final decoded = jsonDecode(rawWidgets!);
      final List<dynamic> widgetsList;
      if (decoded is List) {
        widgetsList = decoded;
      } else if (decoded is Map<String, dynamic> &&
          decoded['widgets'] is List) {
        widgetsList = decoded['widgets'] as List<dynamic>;
      } else {
        widgetsList = [];
      }
      expect(widgetsList.length, 1);
      final widgetJson = widgetsList.first as Map<String, dynamic>;
      expect(widgetJson['title'], 'Temp Difference');
      expect(widgetJson['formula'], 'A - B');
      expect(widgetJson['formulaVariables'], isA<List<dynamic>>());
      final vars = widgetJson['formulaVariables'] as List<dynamic>;
      expect(vars.length, 2);
      expect(vars[0]['name'], 'A');
      expect(vars[0]['field'], 'temp_out');
      expect(vars[1]['name'], 'B');
      expect(vars[1]['field'], 'temp_in');
    });
  });
}
