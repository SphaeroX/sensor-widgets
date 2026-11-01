import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_widgets/domain/models/sensor_data_point.dart';
import 'package:sensor_widgets/domain/models/widget_definition.dart';
import 'package:sensor_widgets/domain/models/widget_type.dart';
import 'package:sensor_widgets/presentation/controllers/widgets_controller.dart';
import 'package:sensor_widgets/presentation/widgets/preview/widget_live_preview_card.dart';

void main() {
  testWidgets('shows a hint when some buckets could not be calculated', (
    tester,
  ) async {
    const def = WidgetDefinition(
      id: 'w',
      type: WidgetType.historyChart,
      title: 'IAQ',
      connectionId: 'c',
      measurement: 'm',
    );
    final data = WidgetPreviewData(
      historyPoints: [
        SensorDataPoint(
          timestamp: DateTime.utc(2026),
          value: 40,
          field: 'formula',
        ),
      ],
      bucketErrors: ['1 Zeit-Bucket nicht berechenbar: Division durch Null'],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WidgetLivePreviewCard(widgetDef: def, previewData: data),
        ),
      ),
    );

    expect(find.textContaining('Division durch Null'), findsOneWidget);
  });
}
