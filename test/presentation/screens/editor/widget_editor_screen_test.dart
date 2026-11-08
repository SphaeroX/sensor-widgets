import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sensor_widgets/data/influx/influx_api_client.dart';
import 'package:sensor_widgets/data/repositories/connection_repository.dart';
import 'package:sensor_widgets/data/repositories/widget_definition_repository.dart';
import 'package:sensor_widgets/data/storage/shared_widget_store.dart';
import 'package:sensor_widgets/domain/models/influx_connection.dart';
import 'package:sensor_widgets/domain/models/influx_field_info.dart';
import 'package:sensor_widgets/domain/models/widget_definition.dart';
import 'package:sensor_widgets/domain/models/widget_type.dart';
import 'package:sensor_widgets/presentation/providers/storage_providers.dart';
import 'package:sensor_widgets/presentation/screens/editor/widget_editor_screen.dart';
import 'package:sensor_widgets/l10n/generated/app_localizations.dart';

import '../../../helpers/editor_sections.dart';

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
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
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
      expect(find.byKey(const Key('widget_type_selector')), findsOneWidget);
      await openEditorSection(tester, 'data_source');
      expect(find.byKey(const Key('widget_measurement_field')), findsOneWidget);
      expect(find.byKey(const Key('widget_field_field')), findsOneWidget);
    });

    testWidgets(
      'switching widget type dynamically shows specific configuration fields',
      (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Switch to History Chart
        await tester.ensureVisible(
          find.byKey(const Key('type_tile_history_chart')),
        );
        await tester.tap(find.byKey(const Key('type_tile_history_chart')));
        await tester.pumpAndSettle();

        await openEditorSection(tester, 'type_settings');
        expect(
          find.byKey(const Key('history_timerange_field')),
          findsOneWidget,
        );

        // Switch to Indicator Lamp
        await openEditorSection(tester, 'basics');
        await tester.ensureVisible(
          find.byKey(const Key('type_tile_indicator_lamp')),
        );
        await tester.tap(find.byKey(const Key('type_tile_indicator_lamp')));
        await tester.pumpAndSettle();

        await openEditorSection(tester, 'type_settings');
        expect(
          find.byKey(const Key('indicator_threshold_field')),
          findsOneWidget,
        );

        // Switch to Gauge Bar
        await openEditorSection(tester, 'basics');
        await tester.ensureVisible(
          find.byKey(const Key('type_tile_gauge_bar')),
        );
        await tester.tap(find.byKey(const Key('type_tile_gauge_bar')));
        await tester.pumpAndSettle();

        await openEditorSection(tester, 'type_settings');
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
      await openEditorSection(tester, 'data_source');
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

    testWidgets(
      'supports guided schema selection via bottom sheets and tag filter editor',
      (tester) async {
        when(
          () => mockApiClient.fetchMeasurements(
            connection: testConn,
            token: 'token-123',
          ),
        ).thenAnswer((_) async => ['climate', 'power']);

        when(
          () => mockApiClient.fetchFieldInfos(
            connection: testConn,
            token: 'token-123',
            measurement: 'climate',
          ),
        ).thenAnswer(
          (_) async => [
            const InfluxFieldInfo(key: 'temperature', type: 'float'),
            const InfluxFieldInfo(key: 'humidity', type: 'float'),
          ],
        );

        when(
          () => mockApiClient.fetchTagKeys(
            connection: testConn,
            token: 'token-123',
            measurement: 'climate',
          ),
        ).thenAnswer((_) async => ['room']);

        when(
          () => mockApiClient.fetchTagValues(
            connection: testConn,
            token: 'token-123',
            measurement: 'climate',
            tagKey: 'room',
          ),
        ).thenAnswer((_) async => ['living_room', 'office']);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('widget_title_field')),
          'Auto Picked Widget',
        );

        // Open measurement picker bottom sheet
        await openEditorSection(tester, 'data_source');
        await tester.ensureVisible(
          find.byKey(const Key('widget_measurement_field')),
        );
        await tester.tap(find.byKey(const Key('widget_measurement_field')));
        await tester.pumpAndSettle();

        expect(find.text('Measurement auswählen'), findsOneWidget);
        expect(find.text('climate'), findsOneWidget);
        await tester.tap(find.text('climate'));
        await tester.pumpAndSettle();

        // Open field picker bottom sheet
        await tester.ensureVisible(find.byKey(const Key('widget_field_field')));
        await tester.tap(find.byKey(const Key('widget_field_field')));
        await tester.pumpAndSettle();

        expect(find.text('Feld auswählen'), findsOneWidget);
        expect(find.text('temperature'), findsOneWidget);
        await tester.tap(find.text('temperature'));
        await tester.pumpAndSettle();

        // Add a tag filter
        await tester.ensureVisible(
          find.byKey(const Key('add_tag_filter_button')),
        );
        await tester.tap(find.byKey(const Key('add_tag_filter_button')));
        await tester.pumpAndSettle();

        expect(find.text('room'), findsOneWidget);
        await tester.tap(find.text('room'));
        await tester.pumpAndSettle();

        expect(find.text('living_room'), findsOneWidget);
        await tester.tap(find.text('living_room'));
        await tester.pumpAndSettle();

        expect(find.text('room = living_room'), findsOneWidget);

        // Save widget
        await tester.tap(find.byKey(const Key('save_widget_button')));
        await tester.pumpAndSettle();

        final captured = verify(() => mockWidgetRepo.saveWidget(captureAny()))
            .captured;
        final savedDef = captured.last as WidgetDefinition;

        expect(savedDef.title, 'Auto Picked Widget');
        expect(savedDef.measurement, 'climate');
        expect(savedDef.field, 'temperature');
        expect(savedDef.tagFilters, {'room': 'living_room'});
      },
    );

    testWidgets(
      'multiValue widget type displays MultiFieldSelector and saves items',
      (tester) async {
        when(
          () => mockApiClient.fetchMeasurements(
            connection: testConn,
            token: 'token-123',
          ),
        ).thenAnswer((_) async => ['climate']);

        when(
          () => mockApiClient.fetchFieldInfos(
            connection: testConn,
            token: 'token-123',
            measurement: 'climate',
          ),
        ).thenAnswer(
          (_) async => [
            const InfluxFieldInfo(key: 'temperature', type: 'float'),
            const InfluxFieldInfo(key: 'humidity', type: 'float'),
          ],
        );

        when(
          () => mockApiClient.fetchTagKeys(
            connection: testConn,
            token: 'token-123',
            measurement: 'climate',
          ),
        ).thenAnswer((_) async => []);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('widget_title_field')),
          'Room Multi Sensors',
        );

        // Switch to Multi-Value
        await tester.ensureVisible(
          find.byKey(const Key('type_tile_multi_value')),
        );
        await tester.tap(find.byKey(const Key('type_tile_multi_value')));
        await tester.pumpAndSettle();

        // Set measurement
        await openEditorSection(tester, 'data_source');
        await tester.ensureVisible(
          find.byKey(const Key('widget_measurement_field')),
        );
        await tester.enterText(
          find.byKey(const Key('widget_measurement_field')),
          'climate',
        );
        await tester.pumpAndSettle();

        // Open MultiFieldSelector sheet
        await tester.ensureVisible(
          find.byKey(const Key('select_multi_fields_button')),
        );
        expect(
          find.byKey(const Key('select_multi_fields_button')),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const Key('select_multi_fields_button')));
        await tester.pumpAndSettle();

        expect(find.text('temperature'), findsOneWidget);
        await tester.tap(find.text('temperature'));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('confirm_multi_fields_button')));
        await tester.pumpAndSettle();

        // Save widget
        await tester.tap(find.byKey(const Key('save_widget_button')));
        await tester.pumpAndSettle();

        final captured = verify(() => mockWidgetRepo.saveWidget(captureAny()))
            .captured;
        final savedDef = captured.last as WidgetDefinition;

        expect(savedDef.type, WidgetType.multiValue);
        expect(savedDef.items, isNotNull);
        expect(savedDef.items!.length, 1);
        expect(savedDef.items!.first.field, 'temperature');
      },
    );

    testWidgets(
      'edit mode pre-populates existing measurement, field, tags, and items',
      (tester) async {
        when(
          () => mockApiClient.fetchMeasurements(
            connection: testConn,
            token: 'token-123',
          ),
        ).thenAnswer((_) async => ['climate']);

        when(
          () => mockApiClient.fetchFieldInfos(
            connection: testConn,
            token: 'token-123',
            measurement: 'climate',
          ),
        ).thenAnswer(
          (_) async => [
            const InfluxFieldInfo(key: 'temperature', type: 'float'),
          ],
        );

        when(
          () => mockApiClient.fetchTagKeys(
            connection: testConn,
            token: 'token-123',
            measurement: 'climate',
          ),
        ).thenAnswer((_) async => ['room']);

        const editDef = WidgetDefinition(
          id: 'existing-1',
          type: WidgetType.singleValue,
          title: 'Existing Widget',
          connectionId: 'conn-1',
          measurement: 'climate',
          field: 'temperature',
          tagFilters: {'room': 'office'},
        );

        await tester.pumpWidget(createTestWidget(widgetToEdit: editDef));
        await tester.pumpAndSettle();

        expect(find.text('Widget bearbeiten'), findsOneWidget);
        expect(find.text('Existing Widget'), findsWidgets);
        await openEditorSection(tester, 'data_source');
        expect(find.text('climate'), findsWidgets);
        expect(find.text('temperature'), findsWidgets);
        expect(find.text('room = office'), findsOneWidget);
      },
    );

    testWidgets(
      'WidgetEditorScreen supports configuring formula and saves formula widget',
      (tester) async {
        when(
          () => mockApiClient.fetchMeasurements(
            connection: testConn,
            token: 'token-123',
          ),
        ).thenAnswer((_) async => ['sensors']);

        when(
          () => mockApiClient.fetchFieldInfos(
            connection: testConn,
            token: 'token-123',
            measurement: 'sensors',
          ),
        ).thenAnswer(
          (_) async => [
            const InfluxFieldInfo(key: 't1', type: 'float'),
            const InfluxFieldInfo(key: 't2', type: 'float'),
          ],
        );

        when(() => mockWidgetRepo.saveWidget(any())).thenAnswer((_) async {});

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('widget_title_field')),
          'Formula Widget',
        );

        await openEditorSection(tester, 'data_source');
        await tester.ensureVisible(
          find.byKey(const Key('widget_measurement_field')),
        );
        await tester.enterText(
          find.byKey(const Key('widget_measurement_field')),
          'sensors',
        );
        await tester.pumpAndSettle();

        // Enable formula switch
        await tester.ensureVisible(find.byType(Switch));
        await tester.tap(find.byType(Switch));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('formula_input_field')), findsOneWidget);

        // Enter formula
        await tester.enterText(
          find.byKey(const Key('formula_input_field')),
          '(A + B) / 2',
        );
        await tester.pumpAndSettle();

        // Add variable B
        await tester.ensureVisible(
          find.byKey(const Key('add_formula_variable_button')),
        );
        await tester.tap(find.byKey(const Key('add_formula_variable_button')));
        await tester.pumpAndSettle();

        // Save
        await tester.tap(find.byKey(const Key('save_widget_button')));
        await tester.pumpAndSettle();

        final captured = verify(() => mockWidgetRepo.saveWidget(captureAny()))
            .captured;
        expect(captured.isNotEmpty, isTrue);
        final saved = captured.last as WidgetDefinition;
        expect(saved.title, 'Formula Widget');
        expect(saved.formula, '(A + B) / 2');
        expect(saved.formulaVariables?.length, 2);
        expect(saved.formulaVariables?[0].name, 'A');
        expect(saved.formulaVariables?[1].name, 'B');
      },
    );
  });
}
