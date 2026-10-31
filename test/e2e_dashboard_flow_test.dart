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
        id: 'dummy',
        name: 'dummy',
        url: 'http://localhost',
        database: 'dummy',
      ),
    );
    registerFallbackValue(
      const WidgetDefinition(
        id: 'dummy',
        type: WidgetType.singleValue,
        title: 'dummy',
        connectionId: 'dummy',
        measurement: 'dummy',
      ),
    );
  });

  group('End-to-End Dashboard Flow Test', () {
    late MockSharedWidgetStore mockSharedStore;
    late MockSecureTokenStore mockTokenStore;
    late MockInfluxApiClient mockApiClient;

    late Map<String, String> sharedStoreMap;
    late Map<String, String> storedTokens;
    int refreshTriggerCount = 0;

    setUp(() {
      mockSharedStore = MockSharedWidgetStore();
      mockTokenStore = MockSecureTokenStore();
      mockApiClient = MockInfluxApiClient();

      sharedStoreMap = {};
      storedTokens = {};
      refreshTriggerCount = 0;

      when(() => mockSharedStore.getString(any())).thenAnswer(
        (inv) async => sharedStoreMap[inv.positionalArguments[0] as String],
      );
      when(() => mockSharedStore.saveString(any(), any()))
          .thenAnswer((inv) async {
            sharedStoreMap[inv.positionalArguments[0] as String] =
                inv.positionalArguments[1] as String;
          });
      when(() => mockSharedStore.notifyWidgetsUpdated()).thenAnswer((_) async {
        refreshTriggerCount++;
      });

      when(() => mockTokenStore.getToken(any())).thenAnswer(
        (inv) async => storedTokens[inv.positionalArguments[0] as String],
      );
      when(() => mockTokenStore.saveToken(any(), any()))
          .thenAnswer((inv) async {
            storedTokens[inv.positionalArguments[0] as String] =
                inv.positionalArguments[1] as String;
          });
      when(() => mockTokenStore.deleteToken(any())).thenAnswer((inv) async {
        storedTokens.remove(inv.positionalArguments[0] as String);
      });

      when(
        () => mockApiClient.testConnection(
          connection: any(named: 'connection'),
          token: any(named: 'token'),
        ),
      ).thenAnswer((_) async => true);

      when(
        () => mockApiClient.fetchMeasurements(
          connection: any(named: 'connection'),
          token: any(named: 'token'),
        ),
      ).thenAnswer((_) async => ['temperature', 'humidity', 'pressure']);

      when(
        () => mockApiClient.fetchFieldKeys(
          connection: any(named: 'connection'),
          token: any(named: 'token'),
          measurement: any(named: 'measurement'),
        ),
      ).thenAnswer((_) async => ['temp', 'humidity', 'val']);

      when(
        () => mockApiClient.fetchTagKeys(
          connection: any(named: 'connection'),
          token: any(named: 'token'),
          measurement: any(named: 'measurement'),
        ),
      ).thenAnswer((_) async => ['room', 'sensor_id']);

      when(
        () => mockApiClient.fetchTagValues(
          connection: any(named: 'connection'),
          token: any(named: 'token'),
          measurement: any(named: 'measurement'),
          tagKey: any(named: 'tagKey'),
        ),
      ).thenAnswer((_) async => ['living_room', 'bedroom']);

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
              'series': [
                {
                  'name': 'temperature',
                  'columns': ['time', 'temp'],
                  'values': [
                    [1700000000000, 22.4],
                  ],
                },
              ],
            },
          ],
        },
      );
    });

    testWidgets(
      'Full flow: add connection -> add multiple widget types -> verify persistence and refresh',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

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

        // 1. Initial Empty Dashboard
        expect(find.text('Sensor Widgets'), findsOneWidget);
        expect(find.text('Noch keine Widgets konfiguriert'), findsOneWidget);

        // 2. Open Connections Screen
        final connAction = find.byKey(const Key('open_connections_btn'));
        expect(connAction, findsOneWidget);
        await tester.tap(connAction);
        await tester.pumpAndSettle();

        expect(find.text('No connections configured'), findsOneWidget);

        // 3. Open Connection Form
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();

        expect(find.text('New Connection'), findsOneWidget);

        // 4. Fill and save connection
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Connection Name'),
          'Home Server',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Host URL'),
          'http://192.168.1.50:8086',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Database / Bucket'),
          'home_data',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'API Token'),
          'secret_token_123',
        );

        // Test connection
        await tester.tap(find.text('Test Connection'));
        await tester.pumpAndSettle();
        expect(find.text('Connection successful!'), findsOneWidget);

        // Save connection
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        List<dynamic> getStoredConnections() =>
            sharedStoreMap[StorageKeys.connectionsMetadataKey] != null
            ? jsonDecode(sharedStoreMap[StorageKeys.connectionsMetadataKey]!)
                  as List<dynamic>
            : [];

        List<dynamic> getStoredWidgets() {
          final raw = sharedStoreMap[StorageKeys.widgetDefinitionsKey];
          if (raw == null) return [];
          final decoded = jsonDecode(raw);
          if (decoded is List) return decoded;
          if (decoded is Map<String, dynamic> && decoded['widgets'] is List) {
            return decoded['widgets'] as List<dynamic>;
          }
          return [];
        }

        expect(find.text('Home Server'), findsOneWidget);
        expect(getStoredConnections().length, 1);
        expect(storedTokens.values.first, 'secret_token_123');

        // 5. Navigate back to Dashboard
        await tester.tap(find.byTooltip('Back'));
        await tester.pumpAndSettle();

        // 6. Add First Widget (Single Value)
        await tester.tap(find.byKey(const Key('add_widget_fab')));
        await tester.pumpAndSettle();

        expect(find.text('Widget konfigurieren'), findsOneWidget);

        await tester.enterText(
          find.byKey(const Key('widget_title_field')),
          'Living Room Temp',
        );
        await tester.enterText(
          find.byKey(const Key('widget_measurement_field')),
          'temperature',
        );
        await tester.enterText(
          find.byKey(const Key('widget_field_field')),
          'temp',
        );
        await tester.enterText(
          find.byKey(const Key('widget_unit_field')),
          '°C',
        );

        await tester.tap(find.byKey(const Key('save_widget_button')));
        await tester.pumpAndSettle();

        expect(find.text('Living Room Temp'), findsOneWidget);
        expect(getStoredWidgets().length, 1);
        expect(getStoredWidgets().first['type'], 'single_value');
        expect(refreshTriggerCount, 1);

        // 7. Add Second Widget (History Chart)
        await tester.tap(find.byKey(const Key('add_widget_fab')));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('widget_title_field')),
          'Temp 24h Chart',
        );
        // Switch widget type to History Chart
        await tester.tap(find.byKey(const Key('widget_type_dropdown')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('History Chart').last);
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('widget_measurement_field')),
          'temperature',
        );
        await tester.enterText(
          find.byKey(const Key('widget_field_field')),
          'temp',
        );

        await tester.tap(find.byKey(const Key('save_widget_button')));
        await tester.pumpAndSettle();

        expect(find.text('Temp 24h Chart'), findsOneWidget);
        expect(getStoredWidgets().length, 2);
        expect(getStoredWidgets()[1]['type'], 'history_chart');
        expect(refreshTriggerCount, 2);

        // 8. Duplicate a widget
        await tester.tap(find.byType(PopupMenuButton<String>).first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Duplizieren'));
        await tester.pumpAndSettle();

        expect(getStoredWidgets().length, 3);
        expect(find.text('Living Room Temp (Kopie)'), findsOneWidget);
        expect(refreshTriggerCount, 3);

        // 9. Delete duplicated widget
        await tester.tap(find.byType(PopupMenuButton<String>).last);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Löschen'));
        await tester.pumpAndSettle();

        expect(getStoredWidgets().length, 2);
        expect(find.text('Living Room Temp (Kopie)'), findsNothing);
        expect(refreshTriggerCount, 4);
      },
    );
  });
}
