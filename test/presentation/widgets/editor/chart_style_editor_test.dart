import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_widgets/domain/models/chart_style.dart';
import 'package:sensor_widgets/presentation/widgets/editor/chart_style_editor.dart';
import 'package:sensor_widgets/l10n/generated/app_localizations.dart';

class _Harness extends StatefulWidget {
  final ChartStyle? initial;
  final void Function(ChartStyle? value) onValue;

  const _Harness({this.initial, required this.onValue});

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  late ChartStyle? style = widget.initial;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: ChartStyleEditor(
            style: style,
            onChanged: (s) {
              setState(() => style = s);
              widget.onValue(s);
            },
          ),
        ),
      ),
    );
  }
}

void main() {
  ChartStyle? latest;

  Future<void> pump(WidgetTester tester, {ChartStyle? initial}) async {
    latest = initial;
    await tester.pumpWidget(
      _Harness(initial: initial, onValue: (s) => latest = s),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('presets fill the color stops', (tester) async {
    await pump(tester);

    await tester.tap(find.byKey(const Key('preset_green_to_red')));
    await tester.pumpAndSettle();

    expect(latest!.colorStops.first.color, '#4CAF50');
    expect(latest!.colorStops.last.color, '#F44336');

    await tester.tap(find.byKey(const Key('preset_red_to_green')));
    await tester.pumpAndSettle();
    expect(latest!.colorStops.first.color, '#F44336');
  });

  testWidgets('stops can be added, edited and removed', (tester) async {
    await pump(tester, initial: const ChartStyle());

    await tester.tap(find.byKey(const Key('add_color_stop_button')));
    await tester.pumpAndSettle();
    expect(latest!.colorStops, hasLength(1));

    await tester.enterText(find.byKey(const Key('color_stop_value_0')), '42.5');
    await tester.enterText(
      find.byKey(const Key('color_stop_color_0')),
      '#112233',
    );
    await tester.pumpAndSettle();
    expect(latest!.colorStops.single.value, 42.5);
    expect(latest!.colorStops.single.color, '#112233');

    await tester.tap(find.byKey(const Key('delete_color_stop_0')));
    await tester.pumpAndSettle();
    expect(latest!.colorStops, isEmpty);
  });

  testWidgets('an invalid hex color is flagged', (tester) async {
    await pump(
      tester,
      initial: const ChartStyle(
        colorStops: [ColorStop(value: 0, color: '#112233')],
      ),
    );
    await tester.enterText(find.byKey(const Key('color_stop_color_0')), 'blau');
    await tester.pumpAndSettle();
    expect(find.text('Ungültige Farbe (#RRGGBB)'), findsOneWidget);
  });

  testWidgets('switches toggle fill, grid, axes and min/max', (tester) async {
    await pump(tester, initial: const ChartStyle());

    for (final key in [
      'chart_fill_switch',
      'chart_grid_switch',
      'chart_axes_switch',
      'chart_minmax_switch',
    ]) {
      await tester.ensureVisible(find.byKey(Key(key)));
      await tester.tap(find.byKey(Key(key)));
      await tester.pumpAndSettle();
    }
    expect(latest!.fillArea, isTrue);
    expect(latest!.showGrid, isTrue);
    expect(latest!.showAxes, isTrue);
    expect(latest!.markMinMax, isTrue);
  });

  testWidgets('line width is editable', (tester) async {
    await pump(tester, initial: const ChartStyle());
    await tester.ensureVisible(find.byKey(const Key('chart_line_width_field')));
    await tester.enterText(
      find.byKey(const Key('chart_line_width_field')),
      '4',
    );
    await tester.pumpAndSettle();
    expect(latest!.lineWidth, 4.0);
  });
}
