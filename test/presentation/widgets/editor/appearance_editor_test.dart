import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_widgets/domain/models/widget_appearance.dart';
import 'package:sensor_widgets/presentation/widgets/editor/appearance_editor.dart';
import 'package:sensor_widgets/l10n/generated/app_localizations.dart';

class _Harness extends StatefulWidget {
  final WidgetAppearance? initial;
  final ValueChanged<WidgetAppearance?> onValue;

  const _Harness({this.initial, required this.onValue});

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  late WidgetAppearance? value = widget.initial;

  @override
  Widget build(BuildContext context) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: SingleChildScrollView(
        child: AppearanceEditor(
          appearance: value,
          onChanged: (a) {
            setState(() => value = a);
            widget.onValue(a);
          },
        ),
      ),
    ),
  );
}

void main() {
  WidgetAppearance? latest;

  Future<void> pump(WidgetTester tester, {WidgetAppearance? initial}) async {
    latest = initial;
    await tester.pumpWidget(
      _Harness(initial: initial, onValue: (a) => latest = a),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('typing a hex color updates the appearance', (tester) async {
    await pump(tester);

    await tester.enterText(
      find.byKey(const Key('appearance_background_color')),
      '#112233',
    );
    await tester.enterText(
      find.byKey(const Key('appearance_text_color')),
      '#FFFFFF',
    );
    await tester.enterText(
      find.byKey(const Key('appearance_accent_color')),
      '#33CC99',
    );
    await tester.pumpAndSettle();

    expect(latest!.backgroundColor, '#112233');
    expect(latest!.textColor, '#FFFFFF');
    expect(latest!.accentColor, '#33CC99');
  });

  testWidgets('palette swatches set the color without typing', (tester) async {
    await pump(tester);

    await tester.ensureVisible(find.byKey(const Key('palette_accent_2')));
    await tester.tap(find.byKey(const Key('palette_accent_2')));
    await tester.pumpAndSettle();

    expect(latest!.accentColor, AppearanceEditor.palette[2]);
  });

  testWidgets('invalid hex is flagged and not applied', (tester) async {
    await pump(tester, initial: const WidgetAppearance(textColor: '#FFFFFF'));

    await tester.enterText(
      find.byKey(const Key('appearance_text_color')),
      'blau',
    );
    await tester.pumpAndSettle();

    expect(find.text('Ungültige Farbe (#RRGGBB)'), findsOneWidget);
    expect(latest!.textColor, '#FFFFFF');
  });

  testWidgets('sliders set opacity, font scale and corner radius', (
    tester,
  ) async {
    await pump(tester);

    for (final key in [
      'appearance_opacity_slider',
      'appearance_font_scale_slider',
      'appearance_corner_radius_slider',
    ]) {
      await tester.ensureVisible(find.byKey(Key(key)));
      final rect = tester.getRect(find.byKey(Key(key)));
      await tester.tapAt(Offset(rect.left + rect.width * 0.75, rect.center.dy));
      await tester.pumpAndSettle();
    }

    expect(latest!.backgroundOpacity, isNotNull);
    expect(latest!.backgroundOpacity, closeTo(0.75, 0.15));
    expect(latest!.fontScale, greaterThan(1.0));
    expect(latest!.cornerRadius, greaterThan(16));
  });

  testWidgets('reset clears the appearance', (tester) async {
    await pump(tester, initial: const WidgetAppearance(accentColor: '#FF5722'));
    await tester.ensureVisible(
      find.byKey(const Key('reset_appearance_button')),
    );
    await tester.tap(find.byKey(const Key('reset_appearance_button')));
    await tester.pumpAndSettle();
    expect(latest, isNull);
  });
}
