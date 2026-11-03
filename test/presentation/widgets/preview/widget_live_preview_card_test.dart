import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_widgets/domain/models/chart_style.dart';
import 'package:sensor_widgets/domain/models/sensor_data_point.dart';
import 'package:sensor_widgets/domain/models/widget_definition.dart';
import 'package:sensor_widgets/domain/models/widget_type.dart';
import 'package:sensor_widgets/presentation/controllers/widgets_controller.dart';
import 'package:sensor_widgets/presentation/widgets/preview/history_chart_painter.dart';
import 'package:sensor_widgets/presentation/widgets/preview/widget_live_preview_card.dart';

void main() {
  group('WidgetLivePreviewCard rounding & decimal formatting', () {
    testWidgets(
      'formats average calculation in singleValue to max 2 decimals without rounding errors',
      (tester) async {
        const widgetDef = WidgetDefinition(
          id: 'w-1',
          type: WidgetType.singleValue,
          title: 'Average Temp',
          connectionId: 'c1',
          measurement: 'climate',
          unit: '°C',
        );

        final previewData = WidgetPreviewData(
          singleValue: SensorDataPoint(
            timestamp: DateTime.now(),
            value: 15.150000000000002, // unrounded float average
            field: 'avg',
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: WidgetLivePreviewCard(
                widgetDef: widgetDef,
                previewData: previewData,
              ),
            ),
          ),
        );

        expect(find.text('15.15'), findsOneWidget);
        expect(find.text('15.150000000000002'), findsNothing);
      },
    );

    testWidgets(
      'formats aggregate MEAN value to max 2 decimals without rounding errors',
      (tester) async {
        const widgetDef = WidgetDefinition(
          id: 'w-agg',
          type: WidgetType.aggregate,
          title: 'Climate Aggregates',
          connectionId: 'c1',
          measurement: 'climate',
          unit: '°C',
        );

        final previewData = WidgetPreviewData(
          aggregateValues: {
            'min': 10.150000000000002,
            'mean': 16.666666666666668,
            'max': 23.333333333333332,
          },
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: WidgetLivePreviewCard(
                widgetDef: widgetDef,
                previewData: previewData,
              ),
            ),
          ),
        );

        // MEAN should be formatted to max 2 decimals (16.67), not 16.7 or 16.66666...
        expect(find.text('16.67 °C'), findsOneWidget);
        expect(find.text('10.15 °C'), findsOneWidget);
        expect(find.text('23.33 °C'), findsOneWidget);
      },
    );
  });

  testWidgets('chart axis labels use the theme font family', (tester) async {
    const widgetDef = WidgetDefinition(
      id: 'w-chart',
      type: WidgetType.historyChart,
      title: 'Chart',
      connectionId: 'c1',
      measurement: 'climate',
      field: 'temp',
      chartStyle: ChartStyle(showAxes: true),
    );
    final previewData = WidgetPreviewData(
      historyPoints: [
        for (var i = 0; i < 3; i++)
          SensorDataPoint(
            timestamp: DateTime.utc(2026, 1, 1, i),
            value: i.toDouble(),
            field: 'temp',
          ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(fontFamily: 'ThemeFont'),
        home: Scaffold(
          body: WidgetLivePreviewCard(
            widgetDef: widgetDef,
            previewData: previewData,
          ),
        ),
      ),
    );

    final paint = tester.widget<CustomPaint>(
      find.byKey(const Key('history_chart_canvas')),
    );
    expect(
      (paint.painter! as HistoryChartPainter).labelFontFamily,
      'ThemeFont',
    );
  });
}
