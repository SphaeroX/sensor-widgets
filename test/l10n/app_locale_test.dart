import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_widgets/app.dart';
import 'package:sensor_widgets/l10n/generated/app_localizations.dart';

/// Shows the resolved locale and one translated string.
class _LocaleProbe extends StatelessWidget {
  const _LocaleProbe();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('locale=${Localizations.localeOf(context).languageCode}'),
        Text(AppLocalizations.of(context).commonCancel),
      ],
    );
  }
}

Future<void> _pumpWithDeviceLocales(
  WidgetTester tester,
  List<Locale> locales,
) async {
  tester.platformDispatcher.localesTestValue = locales;
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  await tester.pumpWidget(
    const SensorWidgetsApp(home: Scaffold(body: _LocaleProbe())),
  );
}

void main() {
  test('English is the first supported locale (fallback)', () {
    expect(AppLocalizations.supportedLocales.first, const Locale('en'));
    expect(
      AppLocalizations.supportedLocales,
      containsAll(const [Locale('en'), Locale('de')]),
    );
  });

  testWidgets('German device locale shows German', (tester) async {
    await _pumpWithDeviceLocales(tester, const [Locale('de', 'DE')]);
    expect(find.text('locale=de'), findsOneWidget);
    expect(find.text('Abbrechen'), findsOneWidget);
  });

  testWidgets('Austrian German falls back to German', (tester) async {
    await _pumpWithDeviceLocales(tester, const [Locale('de', 'AT')]);
    expect(find.text('locale=de'), findsOneWidget);
  });

  testWidgets('English device locale shows English', (tester) async {
    await _pumpWithDeviceLocales(tester, const [Locale('en', 'GB')]);
    expect(find.text('locale=en'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('Unsupported device locale (Hindi) falls back to English', (
    tester,
  ) async {
    await _pumpWithDeviceLocales(tester, const [Locale('hi', 'IN')]);
    expect(find.text('locale=en'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('A supported language later in the device list is used', (
    tester,
  ) async {
    await _pumpWithDeviceLocales(tester, const [
      Locale('hi', 'IN'),
      Locale('de', 'DE'),
    ]);
    expect(find.text('locale=de'), findsOneWidget);
  });
}
