import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sensor_widgets/data/influx/influx_api_client.dart';
import 'package:sensor_widgets/data/repositories/connection_repository.dart';
import 'package:sensor_widgets/data/repositories/widget_definition_repository.dart';
import 'package:sensor_widgets/data/storage/shared_widget_store.dart';
import 'package:sensor_widgets/domain/models/influx_connection.dart';
import 'package:sensor_widgets/domain/models/widget_definition.dart';
import 'package:sensor_widgets/domain/models/widget_type.dart';
import 'package:sensor_widgets/presentation/providers/storage_providers.dart';
import 'package:sensor_widgets/presentation/screens/editor/widget_editor_screen.dart';

class MockWidgetDefinitionRepository extends Mock
    implements WidgetDefinitionRepository {}

class MockConnectionRepository extends Mock implements ConnectionRepository {}

class MockInfluxApiClient extends Mock implements InfluxApiClient {}

class MockSharedWidgetStore extends Mock implements SharedWidgetStore {}

void main() {
  group('WidgetEditorScreen', () {
    late MockWidgetDefinitionRepository mockWidgetRepo;
    late MockConnectionRepository mockConnRepo;
    late MockInfluxApiClient mockApiClient;
    late MockSharedWidgetStore mockSharedStore;

    const testConn = InfluxConnection(
      id: 'conn-1',
      name: 'Server',
      url: 'https://example.com',
      database: 'sensors',
    );

    setUpAll(() {
      registerFallbackValue(
        const WidgetDefinition(
          id: 'dummy',
          type: WidgetType.singleValue,
          title: 'Dummy',
          connectionId: 'conn-1',
          measurement: 'temp',
        ),
      );
    });

    setUp(() {
      mockWidgetRepo = MockWidgetDefinitionRepository();
      mockConnRepo = MockConnectionRepository();
      mockApiClient = MockInfluxApiClient();
      mockSharedStore = MockSharedWidgetStore();

      when(() => mockConnRepo.getConnections())
          .thenAnswer((_) async => [testConn]);
      when(() => mockConnRepo.getConnection('conn-1'))
          .thenAnswer((_) async => testConn);
      when(() => mockConnRepo.getToken('conn-1'))
          .thenAnswer((_) async => 'token-123');
      when(() => mockWidgetRepo.getWidgets()).thenAnswer((_) async => []);
      when(() => mockWidgetRepo.saveWidget(any())).thenAnswer((_) async {});
      when(() => mockSharedStore.notifyWidgetsUpdated())
          .thenAnswer((_) async {});
    });

    Widget createTestWidget({WidgetDefinition? widgetToEdit}) {
      return ProviderScope(
        overrides: [
          widgetDefinitionRepositoryProvider.overrideWithValue(mockWidgetRepo),
          connectionRepositoryProvider.overrideWithValue(mockConnRepo),
          influxApiClientProvider.overrideWithValue(mockApiClient),
          sharedWidgetStoreProvider.overrideWithValue(mockSharedStore),
        ],
        child: MaterialApp(
          home: WidgetEditorScreen(widgetToEdit: widgetToEdit),
        ),
      );
    }

    testWidgets('renders all base form fields for new widget', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Widget konfigurieren'), findsOneWidget);
      expect(find.byKey(const Key('widget_title_field')), findsOneWidget);
      expect(
        find.byKey(const Key('widget_connection_dropdown')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('widget_type_dropdown')), findsOneWidget);
      expect(find.byKey(const Key('widget_measurement_field')), findsOneWidget);
      expect(find.byKey(const Key('widget_field_field')), findsOneWidget);
    });

    testWidgets(
      'switching widget type dynamically shows specific configuration fields',
      (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Switch to History Chart
        await tester.tap(find.byKey(const Key('widget_type_dropdown')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('History Chart').last);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('history_timerange_field')),
          findsOneWidget,
        );

        // Switch to Indicator Lamp
        await tester.tap(find.byKey(const Key('widget_type_dropdown')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Indicator Lamp').last);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('indicator_threshold_field')),
          findsOneWidget,
        );

        // Switch to Gauge Bar
        await tester.tap(find.byKey(const Key('widget_type_dropdown')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Gauge Bar').last);
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('gauge_min_field')), findsOneWidget);
        expect(find.byKey(const Key('gauge_max_field')), findsOneWidget);
      },
    );

    testWidgets('saving valid widget calls repository saveWidget', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('widget_title_field')),
        'Living Room Temp',
      );
      await tester.enterText(
        find.byKey(const Key('widget_measurement_field')),
        'climate',
      );
      await tester.enterText(
        find.byKey(const Key('widget_field_field')),
        'temperature',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('save_widget_button')));
      await tester.pumpAndSettle();

      verify(() => mockWidgetRepo.saveWidget(any())).called(1);
    });
  });
}
