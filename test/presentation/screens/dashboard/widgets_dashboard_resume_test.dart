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

/// Regression: the app stays in memory overnight, so the dashboard showed the
/// values of the evening and the home-screen widgets stayed stale until a
/// manual reload. Coming back to the app reloads both.
void main() {
  const conn = InfluxConnection(
    id: 'c',
    name: 'Server',
    url: 'https://example.com',
    database: 'ha',
  );
  const widget = WidgetDefinition(
    id: 'w1',
    type: WidgetType.singleValue,
    title: 'Temp',
    connectionId: 'c',
    measurement: 'env',
    field: 'temperature',
    unit: '°C',
  );

  Map<String, dynamic> latest(double v) => {
    'results': [
      {
        'statement_id': 0,
        'series': [
          {
            'name': 'env',
            'columns': ['time', 'temperature'],
            'values': [
              [1700000000000, v],
            ],
          },
        ],
      },
    ],
  };

  testWidgets('resuming the app reloads previews and native widgets', (
    tester,
  ) async {
    final repo = _MockWidgetRepo();
    final connRepo = _MockConnRepo();
    final api = _MockApi();
    final store = _MockStore();
    when(() => repo.getWidgets()).thenAnswer((_) async => [widget]);
    when(() => connRepo.getConnections()).thenAnswer((_) async => [conn]);
    when(() => connRepo.getConnection('c')).thenAnswer((_) async => conn);
    when(() => connRepo.getToken('c')).thenAnswer((_) async => 't');
    when(() => store.saveString(any(), any())).thenAnswer((_) async {});
    when(() => store.notifyWidgetsUpdated()).thenAnswer((_) async {});
    var value = 21.0;
    when(
      () => api.query(
        connection: conn,
        token: 't',
        influxQl: any(named: 'influxQl'),
      ),
    ).thenAnswer((_) async => latest(value));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          widgetDefinitionRepositoryProvider.overrideWithValue(repo),
          connectionRepositoryProvider.overrideWithValue(connRepo),
          influxApiClientProvider.overrideWithValue(api),
          sharedWidgetStoreProvider.overrideWithValue(store),
        ],
        child: const SensorWidgetsApp(home: WidgetsDashboardScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('21 °C'), findsOneWidget);
    clearInteractions(store);

    value = 22.5;
    for (final state in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    await tester.pumpAndSettle();

    expect(find.textContaining('22.5 °C'), findsOneWidget);
    verify(() => store.notifyWidgetsUpdated()).called(1);
  });
}
