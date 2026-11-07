import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sensor_widgets/app.dart';
import 'package:sensor_widgets/data/influx/influx_api_client.dart';
import 'package:sensor_widgets/data/repositories/connection_repository.dart';
import 'package:sensor_widgets/data/repositories/widget_definition_repository.dart';
import 'package:sensor_widgets/data/storage/shared_widget_store.dart';
import 'package:sensor_widgets/domain/models/influx_connection.dart';
import 'package:sensor_widgets/domain/models/widget_definition.dart';
import 'package:sensor_widgets/domain/models/widget_type.dart';
import 'package:sensor_widgets/presentation/providers/storage_providers.dart';
import 'package:sensor_widgets/presentation/screens/dashboard/widgets_dashboard_screen.dart';

class _MockWidgetRepo extends Mock implements WidgetDefinitionRepository {}

class _MockConnRepo extends Mock implements ConnectionRepository {}

class _MockApi extends Mock implements InfluxApiClient {}

class _MockStore extends Mock implements SharedWidgetStore {}

/// The dashboard card shows the widget's real data (same query as the editor
/// preview) instead of a fixed placeholder, so a saved change is visible there.
void main() {
  const conn = InfluxConnection(
    id: 'c',
    name: 'Server',
    url: 'https://example.com',
    database: 'ha',
  );
  const widget = WidgetDefinition(
    id: 'w1',
    type: WidgetType.historyChart,
    title: 'test',
    connectionId: 'c',
    measurement: '°C',
    field: 'value',
    unit: '°C',
    timeRange: '24h',
    aggregationInterval: '1h',
  );

  Map<String, dynamic> series(List<double> values) => {
    'results': [
      {
        'statement_id': 0,
        'series': [
          {
            'name': '°C',
            'columns': ['time', 'mean'],
            'values': [
              for (var i = 0; i < values.length; i++)
                [1700000000000 + i * 3600000, values[i]],
            ],
          },
        ],
      },
    ],
  };

  testWidgets('history chart card shows the latest value and a live chart', (
    tester,
  ) async {
    final repo = _MockWidgetRepo();
    final connRepo = _MockConnRepo();
    final api = _MockApi();
    when(() => repo.getWidgets()).thenAnswer((_) async => [widget]);
    when(() => connRepo.getConnections()).thenAnswer((_) async => [conn]);
    when(() => connRepo.getConnection('c')).thenAnswer((_) async => conn);
    when(() => connRepo.getToken('c')).thenAnswer((_) async => 't');
    when(
      () => api.query(
        connection: conn,
        token: 't',
        influxQl: any(named: 'influxQl'),
      ),
    ).thenAnswer((_) async => series([3, 18.65, -1.1, 6]));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          widgetDefinitionRepositoryProvider.overrideWithValue(repo),
          connectionRepositoryProvider.overrideWithValue(connRepo),
          influxApiClientProvider.overrideWithValue(api),
          sharedWidgetStoreProvider.overrideWithValue(_MockStore()),
        ],
        child: const SensorWidgetsApp(home: WidgetsDashboardScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('dashboard_card_live_w1')), findsOneWidget);
    expect(find.textContaining('6 °C'), findsOneWidget);
  });
}
