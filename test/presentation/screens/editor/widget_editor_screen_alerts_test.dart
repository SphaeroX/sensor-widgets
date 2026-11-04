import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sensor_widgets/data/influx/influx_api_client.dart';
import 'package:sensor_widgets/data/platform/notification_permission.dart';
import 'package:sensor_widgets/data/repositories/connection_repository.dart';
import 'package:sensor_widgets/data/repositories/widget_definition_repository.dart';
import 'package:sensor_widgets/data/storage/shared_widget_store.dart';
import 'package:sensor_widgets/domain/models/influx_connection.dart';
import 'package:sensor_widgets/domain/models/alert_rule.dart';
import 'package:sensor_widgets/domain/models/sensor_query_item.dart';
import 'package:sensor_widgets/domain/models/threshold_rule.dart';
import 'package:sensor_widgets/domain/models/widget_definition.dart';
import 'package:sensor_widgets/domain/models/widget_type.dart';
import 'package:sensor_widgets/presentation/providers/storage_providers.dart';
import 'package:sensor_widgets/presentation/screens/editor/widget_editor_screen.dart';

class MockWidgetRepo extends Mock implements WidgetDefinitionRepository {}

class MockConnRepo extends Mock implements ConnectionRepository {}

class MockApi extends Mock implements InfluxApiClient {}

class MockStore extends Mock implements SharedWidgetStore {}

class MockPermission extends Mock implements NotificationPermission {}

void main() {
  const conn = InfluxConnection(
    id: 'conn-1',
    name: 'Server',
    url: 'https://example.com',
    database: 'sensors',
  );
  late MockWidgetRepo widgetRepo;
  late MockPermission permission;

  setUpAll(() {
    registerFallbackValue(conn);
    registerFallbackValue(
      const WidgetDefinition(
        id: 'd',
        type: WidgetType.singleValue,
        title: 'D',
        connectionId: 'conn-1',
        measurement: 'm',
      ),
    );
  });

  Widget app(WidgetDefinition edit) {
    widgetRepo = MockWidgetRepo();
    final connRepo = MockConnRepo();
    final api = MockApi();
    final store = MockStore();
    permission = MockPermission();
    when(() => permission.request()).thenAnswer((_) async => true);
    when(() => connRepo.getConnections()).thenAnswer((_) async => [conn]);
    when(() => connRepo.getConnection('conn-1')).thenAnswer((_) async => conn);
    when(() => connRepo.getToken('conn-1')).thenAnswer((_) async => 'tok');
    when(() => widgetRepo.getWidgets()).thenAnswer((_) async => []);
    when(() => widgetRepo.saveWidget(any())).thenAnswer((_) async {});
    when(() => store.notifyWidgetsUpdated()).thenAnswer((_) async {});
    when(
      () => api.fetchMeasurements(
        connection: any(named: 'connection'),
        token: any(named: 'token'),
      ),
    ).thenAnswer((_) async => ['climate']);
    when(
      () => api.fetchFieldInfos(
        connection: any(named: 'connection'),
        token: any(named: 'token'),
        measurement: any(named: 'measurement'),
      ),
    ).thenAnswer((_) async => []);
    when(
      () => api.fetchTagKeys(
        connection: any(named: 'connection'),
        token: any(named: 'token'),
        measurement: any(named: 'measurement'),
      ),
    ).thenAnswer((_) async => []);
    return ProviderScope(
      overrides: [
        widgetDefinitionRepositoryProvider.overrideWithValue(widgetRepo),
        connectionRepositoryProvider.overrideWithValue(connRepo),
        influxApiClientProvider.overrideWithValue(api),
        sharedWidgetStoreProvider.overrideWithValue(store),
        notificationPermissionProvider.overrideWithValue(permission),
      ],
      child: MaterialApp(home: WidgetEditorScreen(widgetToEdit: edit)),
    );
  }

  const base = WidgetDefinition(
    id: 'w1',
    type: WidgetType.singleValue,
    title: 'CO2',
    connectionId: 'conn-1',
    measurement: 'climate',
    field: 'co2',
  );

  Future<WidgetDefinition> save(WidgetTester tester) async {
    await tester.ensureVisible(find.byKey(const Key('save_widget_button')));
    await tester.tap(find.byKey(const Key('save_widget_button')));
    await tester.pumpAndSettle();
    return verify(() => widgetRepo.saveWidget(captureAny())).captured.last
        as WidgetDefinition;
  }

  testWidgets('a notification rule is added, asks for permission and saved', (
    tester,
  ) async {
    await tester.pumpWidget(app(base));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('alert_add_button')));
    await tester.tap(find.byKey(const Key('alert_add_button')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('alert_value_0')), '1000');
    await tester.pumpAndSettle();

    final saved = await save(tester);
    expect(saved.alerts, const [
      AlertRule(
        target: AlertRule.targetValue,
        operator: ThresholdOperator.greaterThan,
        value: 1000,
      ),
    ]);
    verify(() => permission.request()).called(1);
  });

  testWidgets('existing rules are loaded and kept when saving', (tester) async {
    const rule = AlertRule(
      target: 'value',
      operator: ThresholdOperator.lessThan,
      value: 400,
    );
    await tester.pumpWidget(app(base.copyWith(alerts: const [rule])));
    await tester.pumpAndSettle();

    final saved = await save(tester);
    expect(saved.alerts, const [rule]);
  });

  testWidgets('multi value rows are offered as targets', (tester) async {
    await tester.pumpWidget(
      app(
        const WidgetDefinition(
          id: 'w2',
          type: WidgetType.multiValue,
          title: 'sen66',
          connectionId: 'conn-1',
          measurement: 'climate',
          items: [
            SensorQueryItem(field: 'co2', label: 'CO2'),
            SensorQueryItem(field: 'temp', label: 'Temperatur'),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('alert_add_button')));
    await tester.tap(find.byKey(const Key('alert_add_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('alert_target_0')), findsOneWidget);
    final saved = await save(tester);
    expect(saved.alerts!.single.target, 'co2');
  });

  testWidgets('widgets without rules save without an alerts block', (
    tester,
  ) async {
    await tester.pumpWidget(app(base));
    await tester.pumpAndSettle();

    final saved = await save(tester);
    expect(saved.alerts, isNull);
    verifyNever(() => permission.request());
  });
}
