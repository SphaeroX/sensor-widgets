// Generates the README screenshots into docs/screenshots/ (never compares them).
//
//   flutter test screenshot_test
//
// Runs headless, also in the "Screenshots" GitHub Actions workflow.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_widgets/core/theme/app_theme.dart';
import 'package:sensor_widgets/domain/models/chart_style.dart';
import 'package:sensor_widgets/domain/models/sensor_data_point.dart';
import 'package:sensor_widgets/domain/models/sensor_query_item.dart';
import 'package:sensor_widgets/domain/models/threshold_rule.dart';
import 'package:sensor_widgets/domain/models/widget_definition.dart';
import 'package:sensor_widgets/domain/models/widget_type.dart';
import 'package:sensor_widgets/presentation/controllers/widgets_controller.dart';
import 'package:sensor_widgets/presentation/screens/connections/connection_form_screen.dart';
import 'package:sensor_widgets/presentation/screens/dashboard/widgets_dashboard_screen.dart';
import 'package:sensor_widgets/presentation/widgets/preview/widget_live_preview_card.dart';

import 'support/screenshot_harness.dart';

import 'package:sensor_widgets/l10n/generated/app_localizations.dart';

final _now = DateTime.utc(2026, 11, 3, 14);

SensorDataPoint _point(String field, double value, [DateTime? at]) =>
    SensorDataPoint(timestamp: at ?? _now, value: value, field: field);

List<SensorDataPoint> _iaqCurve() => [
  for (var i = 0; i < 48; i++)
    _point(
      'iaq',
      (60 + 25 * math.sin(i / 7) + 8 * math.sin(i / 2)).roundToDouble(),
      _now.subtract(Duration(minutes: 30 * (47 - i))),
    ),
];

/// One example per widget type, with the data the native widget would show.
final _typeExamples = <String, (WidgetDefinition, WidgetPreviewData)>{
  'single_value': (
    const WidgetDefinition(
      id: 'temp',
      type: WidgetType.singleValue,
      title: 'Wohnzimmer',
      connectionId: 'demo',
      measurement: 'sen66',
      field: 'temperature',
      unit: '°C',
      decimalPlaces: 1,
    ),
    WidgetPreviewData(
      singleValue: _point('temperature', 22.4),
      fetchedAt: _now,
    ),
  ),
  'history_chart': (
    const WidgetDefinition(
      id: 'iaq',
      type: WidgetType.historyChart,
      title: 'IAQ Index',
      connectionId: 'demo',
      measurement: 'sen66',
      field: 'iaq',
      unit: 'IAQ',
      timeRange: '24h',
      aggregationInterval: '30m',
      chartStyle: ChartStyle(
        colorStops: ChartStyle.redToGreenStops,
        fillArea: true,
        showGrid: true,
        showAxes: true,
      ),
    ),
    WidgetPreviewData(historyPoints: _iaqCurve(), fetchedAt: _now),
  ),
  'indicator_lamp': (
    const WidgetDefinition(
      id: 'window',
      type: WidgetType.indicatorLamp,
      title: 'Lüften?',
      connectionId: 'demo',
      measurement: 'sen66',
      field: 'co2',
      unit: 'ppm',
      decimalPlaces: 0,
      threshold: ThresholdRule(
        operator: ThresholdOperator.greaterThan,
        value: 1000,
      ),
    ),
    WidgetPreviewData(singleValue: _point('co2', 1240), fetchedAt: _now),
  ),
  'gauge_bar': (
    const WidgetDefinition(
      id: 'humidity',
      type: WidgetType.gaugeBar,
      title: 'Luftfeuchte',
      connectionId: 'demo',
      measurement: 'sen66',
      field: 'humidity',
      unit: '%',
      decimalPlaces: 0,
      min: 0,
      max: 100,
    ),
    WidgetPreviewData(singleValue: _point('humidity', 46), fetchedAt: _now),
  ),
  'aggregate': (
    const WidgetDefinition(
      id: 'co2-day',
      type: WidgetType.aggregate,
      title: 'CO2 heute',
      connectionId: 'demo',
      measurement: 'sen66',
      field: 'co2',
      unit: 'ppm',
      decimalPlaces: 0,
      timeRange: '24h',
    ),
    WidgetPreviewData(
      aggregateValues: const {'min': 612, 'mean': 834, 'max': 1240},
      fetchedAt: _now,
    ),
  ),
  'multi_value': (
    const WidgetDefinition(
      id: 'sen66',
      type: WidgetType.multiValue,
      title: 'SEN66',
      connectionId: 'demo',
      measurement: 'sen66',
      items: [
        SensorQueryItem(field: 'co2', label: 'CO2', unit: 'ppm'),
        SensorQueryItem(field: 'voc_index', label: 'VOC'),
        SensorQueryItem(field: 'nox_index', label: 'NOx'),
        SensorQueryItem(field: 'pm2_5', label: 'PM2.5', unit: 'µg/m³'),
      ],
    ),
    WidgetPreviewData(
      multiValues: {
        'co2': _point('co2', 1734),
        'voc_index': _point('voc_index', 192),
        'nox_index': _point('nox_index', 1),
        'pm2_5': _point('pm2_5', 4.2),
      },
      fetchedAt: _now,
    ),
  ),
};

void main() {
  setUpAll(() async {
    await loadScreenshotFonts();
    final current = goldenFileComparator as LocalFileComparator;
    goldenFileComparator = WriteOnlyGoldenComparator(
      current.basedir.resolve('readme_screenshots_test.dart'),
    );
  });

  group('widget types', () {
    for (final entry in _typeExamples.entries) {
      testWidgets(entry.key, (tester) async {
        final (definition, data) = entry.value;
        tester.view.physicalSize = const Size(380, 300) * screenshotPixelRatio;
        tester.view.devicePixelRatio = screenshotPixelRatio;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.dark(),
            home: Scaffold(
              body: Center(
                child: RepaintBoundary(
                  key: const Key('capture'),
                  child: Container(
                    width: 360,
                    padding: const EdgeInsets.all(10),
                    color: AppTheme.dark().scaffoldBackgroundColor,
                    child: WidgetLivePreviewCard(
                      widgetDef: definition,
                      previewData: data,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await expectLater(
          find.byKey(const Key('capture')),
          matchesGoldenFile('../docs/screenshots/widget_${entry.key}.png'),
        );
      });
    }
  });

  testWidgets('dashboard', (tester) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(
      screenshotApp(
        home: const WidgetsDashboardScreen(),
        widgets: [for (final e in _typeExamples.values) e.$1],
      ),
    );
    await tester.pumpAndSettle();
    await captureScreen('app_dashboard');
  });

  testWidgets('add connection', (tester) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(screenshotApp(home: const ConnectionFormScreen()));
    await tester.pumpAndSettle();

    Future<void> fill(String label, String text) async {
      await tester.enterText(find.widgetWithText(TextFormField, label), text);
      await tester.pumpAndSettle();
    }

    await fill('Connection Name', 'Home Lab');
    await fill('Host URL', 'https://influx.example.com');
    await fill('Database / Bucket', 'sensors');
    await fill('API Token', 'demo-token-not-real');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await captureScreen('app_add_connection');
  });

  testWidgets('new widget with live preview', (tester) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(
      screenshotApp(home: const WidgetsDashboardScreen()),
    );
    await tester.pumpAndSettle();

    await tapKey(tester, 'add_widget_fab');
    await tester.enterText(
      find.byKey(const Key('widget_title_field')),
      'CO2 Wohnzimmer',
    );
    await tapKey(tester, 'type_tile_history_chart');
    await tester.enterText(
      find.byKey(const Key('widget_measurement_field')),
      'sen66',
    );
    await tester.enterText(find.byKey(const Key('widget_field_field')), 'co2');
    await tester.enterText(find.byKey(const Key('widget_unit_field')), 'ppm');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tapKey(tester, 'preview_data_button');

    await tester.ensureVisible(find.byKey(const Key('widget_type_selector')));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 2000));
    await tester.pumpAndSettle();
    await captureScreen('app_new_widget');
  });

  testWidgets('formula templates and editor', (tester) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(
      screenshotApp(home: const WidgetsDashboardScreen()),
    );
    await tester.pumpAndSettle();

    await tapKey(tester, 'add_widget_fab');
    await tester.enterText(
      find.byKey(const Key('widget_title_field')),
      'IAQ Index',
    );
    await tapKey(tester, 'type_tile_history_chart');
    await tester.enterText(
      find.byKey(const Key('widget_measurement_field')),
      'sen66',
    );
    await tester.pumpAndSettle();
    await tapKey(tester, 'formula_enabled_switch');
    await tapKey(tester, 'formula_help_button');

    await tester.scrollUntilVisible(
      find.byKey(const Key('apply_template_iaq_sen66')),
      300,
    );
    await tester.pumpAndSettle();
    await captureScreen('app_formula_templates');

    await tapKey(tester, 'apply_template_iaq_sen66');
    const mapping = {
      'co2': 'co2',
      'voc': 'voc_index',
      'pm25': 'pm2_5',
      'rh': 'humidity',
    };
    for (final entry in mapping.entries) {
      await tapKey(tester, 'edit_variable_${entry.key}_button');
      await tester.tap(find.byKey(const Key('variable_field_input')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(entry.value).last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('apply_variable_button')));
      await tester.pumpAndSettle();
    }
    await tapKey(tester, 'preset_red_to_green');
    await tapKey(tester, 'chart_fill_switch');

    await tester.ensureVisible(find.byKey(const Key('formula_enabled_switch')));
    await tester.pumpAndSettle();
    await captureScreen('app_formula_editor');

    await tapKey(tester, 'preview_data_button');
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 4000));
    await tester.pumpAndSettle();
    await captureScreen('app_formula_preview');
  });
}
