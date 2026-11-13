import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sensor_widgets/core/constants/app_links.dart';
import 'package:sensor_widgets/data/influx/influx_api_client.dart';
import 'package:sensor_widgets/data/platform/external_link_launcher.dart';
import 'package:sensor_widgets/data/repositories/connection_repository.dart';
import 'package:sensor_widgets/data/repositories/widget_definition_repository.dart';
import 'package:sensor_widgets/data/storage/shared_widget_store.dart';
import 'package:sensor_widgets/l10n/generated/app_localizations.dart';
import 'package:sensor_widgets/presentation/providers/storage_providers.dart';
import 'package:sensor_widgets/presentation/screens/dashboard/widgets_dashboard_screen.dart';

class MockWidgetRepo extends Mock implements WidgetDefinitionRepository {}

class MockConnRepo extends Mock implements ConnectionRepository {}

class MockApi extends Mock implements InfluxApiClient {}

class MockStore extends Mock implements SharedWidgetStore {}

class MockLinkLauncher extends Mock implements ExternalLinkLauncher {}

void main() {
  setUpAll(() => registerFallbackValue(Uri()));

  Future<void> pumpDashboard(
    WidgetTester tester,
    ExternalLinkLauncher launcher,
  ) async {
    final widgetRepo = MockWidgetRepo();
    final connRepo = MockConnRepo();
    when(() => widgetRepo.getWidgets()).thenAnswer((_) async => []);
    when(() => connRepo.getConnections()).thenAnswer((_) async => []);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          widgetDefinitionRepositoryProvider.overrideWithValue(widgetRepo),
          connectionRepositoryProvider.overrideWithValue(connRepo),
          influxApiClientProvider.overrideWithValue(MockApi()),
          sharedWidgetStoreProvider.overrideWithValue(MockStore()),
          externalLinkLauncherProvider.overrideWithValue(launcher),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: WidgetsDashboardScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  test('repository url points to the public GitHub repository', () {
    expect(
      AppLinks.repository,
      Uri.parse('https://github.com/SphaeroX/sensor-widgets'),
    );
  });

  testWidgets('dashboard app bar opens the GitHub repository', (tester) async {
    final launcher = MockLinkLauncher();
    when(() => launcher.open(any())).thenAnswer((_) async => true);

    await pumpDashboard(tester, launcher);

    final button = find.byKey(const Key('open_github_repo_btn'));
    expect(button, findsOneWidget);
    expect(find.byTooltip('GitHub'), findsOneWidget);

    await tester.tap(button);
    await tester.pumpAndSettle();

    verify(() => launcher.open(AppLinks.repository)).called(1);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('shows a snack bar when the link cannot be opened', (
    tester,
  ) async {
    final launcher = MockLinkLauncher();
    when(() => launcher.open(any())).thenAnswer((_) async => false);

    await pumpDashboard(tester, launcher);

    await tester.tap(find.byKey(const Key('open_github_repo_btn')));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(
      find.textContaining('https://github.com/SphaeroX/sensor-widgets'),
      findsOneWidget,
    );
  });
}
