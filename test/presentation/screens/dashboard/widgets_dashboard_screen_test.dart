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
    group('layout', () {
      List<WidgetDefinition> many(int n) => List.generate(
        n,
        (i) => WidgetDefinition(
          id: 'w-$i',
          type: WidgetType.multiValue,
          title: 'Widget $i',
          connectionId: 'conn-1',
          measurement: 'environment',
        ),
      );

      Future<void> pumpDashboard(
        WidgetTester tester, {
        required List<WidgetDefinition> widgets,
        EdgeInsets padding = EdgeInsets.zero,
      }) async {
        when(() => mockWidgetRepo.getWidgets())
            .thenAnswer((_) async => widgets);
        tester.view.physicalSize = const Size(360, 480);
        tester.view.devicePixelRatio = 1.0;
        tester.view.padding = FakeViewPadding(
          top: padding.top,
          bottom: padding.bottom,
        );
        tester.view.viewPadding = tester.view.padding;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();
      }

      for (final count in [1, 10]) {
        testWidgets('first card starts below the AppBar ($count widgets)', (
          tester,
        ) async {
          await pumpDashboard(
            tester,
            widgets: many(count),
            padding: const EdgeInsets.only(top: 48, bottom: 24),
          );

          final appBarBottom = tester.getBottomLeft(find.byType(AppBar)).dy;
          final firstCardTop = tester.getTopLeft(find.byType(Card).first).dy;
          expect(firstCardTop, greaterThanOrEqualTo(appBarBottom));
        });
      }

      testWidgets('list scrolls to the last entry on a small viewport', (
        tester,
      ) async {
        await pumpDashboard(tester, widgets: many(10));

        await tester.scrollUntilVisible(
          find.text('Widget 9'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('Widget 9'), findsOneWidget);
      });

      testWidgets('empty state is centered in the body', (tester) async {
        await pumpDashboard(tester, widgets: const []);

        final appBarBottom = tester.getBottomLeft(find.byType(AppBar)).dy;
        final center = tester.getCenter(
          find.text('Noch keine Widgets konfiguriert'),
        );
        expect(center.dx, closeTo(180, 1));
        expect(center.dy, greaterThan(appBarBottom));
      });
    });
  });
}
