import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_widgets/domain/models/sensor_data_point.dart';
import 'package:sensor_widgets/domain/models/widget_definition.dart';
import 'package:sensor_widgets/domain/models/widget_type.dart';
import 'package:sensor_widgets/presentation/controllers/widgets_controller.dart';
import 'package:sensor_widgets/presentation/widgets/preview/widget_live_preview_card.dart';

void main() {
  testWidgets('multi-value preview shows row errors next to good rows', (
    tester,
  ) async {
    const def = WidgetDefinition(
      id: 'w',
      type: WidgetType.multiValue,
      title: 'Room',
      connectionId: 'c',
      measurement: 'm',
    );
    final data = WidgetPreviewData(
      multiValues: {
        'temp': SensorDataPoint(
          timestamp: DateTime.utc(2026),
          value: 21.5,
          field: 'temp',
        ),
      },
      multiErrors: {'ratio': 'Division durch Null'},
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WidgetLivePreviewCard(widgetDef: def, previewData: data),
        ),
      ),
    );

    expect(find.text('temp'), findsOneWidget);
    expect(find.text('ratio'), findsOneWidget);
    expect(find.textContaining('Division durch Null'), findsOneWidget);
  });
}
