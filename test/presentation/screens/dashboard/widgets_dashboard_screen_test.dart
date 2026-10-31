import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sensor_widgets/data/influx/influx_api_client.dart';
import 'package:sensor_widgets/data/repositories/connection_repository.dart';
import 'package:sensor_widgets/data/repositories/widget_definition_repository.dart';
import 'package:sensor_widgets/data/storage/shared_widget_store.dart';
import 'package:sensor_widgets/domain/models/widget_definition.dart';
import 'package:sensor_widgets/domain/models/widget_type.dart';
import 'package:sensor_widgets/presentation/providers/storage_providers.dart';
import 'package:sensor_widgets/presentation/screens/dashboard/widgets_dashboard_screen.dart';

class MockWidgetDefinitionRepository extends Mock
    implements WidgetDefinitionRepository {}

class MockConnectionRepository extends Mock implements ConnectionRepository {}

class MockInfluxApiClient extends Mock implements InfluxApiClient {}

class MockSharedWidgetStore extends Mock implements SharedWidgetStore {}

void main() {
  group('WidgetsDashboardScreen', () {
    late MockWidgetDefinitionRepository mockWidgetRepo;
    late MockConnectionRepository mockConnRepo;
    late MockInfluxApiClient mockApiClient;
    late MockSharedWidgetStore mockSharedStore;

    const testWidget = WidgetDefinition(
      id: 'w-1',
      type: WidgetType.singleValue,
      title: 'Living Room Temp',
      connectionId: 'conn-1',
      measurement: 'climate',
      field: 'temp',
    );

    setUpAll(() {
      registerFallbackValue(testWidget);
    });

    setUp(() {
      mockWidgetRepo = MockWidgetDefinitionRepository();
      mockConnRepo = MockConnectionRepository();
      mockApiClient = MockInfluxApiClient();
      mockSharedStore = MockSharedWidgetStore();

      when(() => mockWidgetRepo.getWidgets())
          .thenAnswer((_) async => [testWidget]);
      when(() => mockConnRepo.getConnections()).thenAnswer((_) async => []);
      when(() => mockSharedStore.notifyWidgetsUpdated())
          .thenAnswer((_) async {});
    });

    Widget createTestWidget() {
      return ProviderScope(
        overrides: [
          widgetDefinitionRepositoryProvider.overrideWithValue(mockWidgetRepo),
          connectionRepositoryProvider.overrideWithValue(mockConnRepo),
          influxApiClientProvider.overrideWithValue(mockApiClient),
          sharedWidgetStoreProvider.overrideWithValue(mockSharedStore),
        ],
        child: const MaterialApp(home: WidgetsDashboardScreen()),
      );
    }

    testWidgets('renders list of configured widgets', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Living Room Temp'), findsOneWidget);
      expect(find.text('Single Value'), findsOneWidget);
    });

    testWidgets('tapping refresh button calls notifyWidgetsUpdated', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final refreshBtn = find.byKey(const Key('refresh_native_widgets_btn'));
      expect(refreshBtn, findsOneWidget);
      await tester.tap(refreshBtn);
      await tester.pumpAndSettle();

      verify(() => mockSharedStore.notifyWidgetsUpdated()).called(1);
    });
  });
}
