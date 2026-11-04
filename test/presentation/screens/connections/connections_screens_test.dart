import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sensor_widgets/data/influx/influx_api_client.dart';
import 'package:sensor_widgets/data/repositories/connection_repository.dart';
import 'package:sensor_widgets/domain/models/influx_connection.dart';
import 'package:sensor_widgets/presentation/providers/storage_providers.dart';
import 'package:sensor_widgets/presentation/screens/connections/connection_form_screen.dart';
import 'package:sensor_widgets/presentation/screens/connections/connections_list_screen.dart';
import 'package:sensor_widgets/l10n/generated/app_localizations.dart';

import '../../../l10n/english_locale.dart';

class MockConnectionRepository extends Mock implements ConnectionRepository {}

class MockInfluxApiClient extends Mock implements InfluxApiClient {}

void main() {
  useEnglishDeviceLocale();

  setUpAll(() {
    registerFallbackValue(
      const InfluxConnection(
        id: 'dummy',
        name: 'dummy',
        url: 'https://dummy.com',
        database: 'dummy',
      ),
    );
  });

  group('Connections Screens', () {
    late MockConnectionRepository mockRepo;
    late MockInfluxApiClient mockApiClient;

    const testConn = InfluxConnection(
      id: 'conn-1',
      name: 'Primary Influx',
      url: 'https://influx.example.com:8086',
      database: 'sensors',
    );

    setUp(() {
      mockRepo = MockConnectionRepository();
      mockApiClient = MockInfluxApiClient();
    });

    testWidgets(
      'ConnectionsListScreen renders empty state when no connections',
      (tester) async {
        when(() => mockRepo.getConnections()).thenAnswer((_) async => []);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              connectionRepositoryProvider.overrideWithValue(mockRepo),
            ],
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: ConnectionsListScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('No connections configured'), findsOneWidget);
        expect(find.byType(FloatingActionButton), findsOneWidget);
      },
    );

    testWidgets('ConnectionsListScreen renders connection items', (
      tester,
    ) async {
      when(() => mockRepo.getConnections()).thenAnswer((_) async => [testConn]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [connectionRepositoryProvider.overrideWithValue(mockRepo)],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ConnectionsListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Primary Influx'), findsOneWidget);
      expect(
        find.textContaining('https://influx.example.com:8086'),
        findsOneWidget,
      );
    });

    testWidgets('ConnectionFormScreen validates fields and tests connection', (
      tester,
    ) async {
      when(
        () => mockApiClient.testConnection(
          connection: any(named: 'connection'),
          token: any(named: 'token'),
        ),
      ).thenAnswer((_) async => true);
      when(() => mockRepo.saveConnection(any(), token: any(named: 'token')))
          .thenAnswer((_) async {});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            connectionRepositoryProvider.overrideWithValue(mockRepo),
            influxApiClientProvider.overrideWithValue(mockApiClient),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ConnectionFormScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap save without filling -> validation error
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a connection name'), findsOneWidget);

      // Fill in fields
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Connection Name'),
        'My Server',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Host URL'),
        'https://myserver.com:8086',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Database / Bucket'),
        'homelab',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'API Token'),
        'my-token',
      );
      await tester.pumpAndSettle();

      // Test connection
      await tester.tap(find.text('Test Connection'));
      await tester.pumpAndSettle();

      expect(find.text('Connection successful!'), findsOneWidget);
    });
  });
}
