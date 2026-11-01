import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_widgets/domain/models/sensor_data_point.dart';
import 'package:sensor_widgets/domain/models/widget_appearance.dart';
import 'package:sensor_widgets/domain/models/widget_definition.dart';
import 'package:sensor_widgets/domain/models/widget_type.dart';
import 'package:sensor_widgets/presentation/controllers/widgets_controller.dart';
import 'package:sensor_widgets/presentation/widgets/preview/widget_live_preview_card.dart';

WidgetDefinition _def({WidgetAppearance? appearance}) => WidgetDefinition(
  id: 'w',
  type: WidgetType.singleValue,
  title: 'Wohnzimmer',
  connectionId: 'c',
  measurement: 'm',
  field: 'f',
  unit: '°C',
  appearance: appearance,
);

Future<void> _pump(WidgetTester tester, WidgetDefinition def) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: WidgetLivePreviewCard(
          widgetDef: def,
          previewData: WidgetPreviewData(
            singleValue: SensorDataPoint(
              timestamp: DateTime.utc(2026),
              value: 21.5,
              field: 'f',
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  const styled = WidgetAppearance(
    backgroundColor: '#102030',
    backgroundOpacity: 0.5,
    textColor: '#FFEEAA',
    accentColor: '#33CC99',
    fontScale: 1.5,
    cornerRadius: 24,
  );

  testWidgets('applies background, opacity and corner radius', (tester) async {
    await _pump(tester, _def(appearance: styled));

    final card = tester.widget<Card>(find.byType(Card));
    expect(card.color!.toARGB32() & 0xFFFFFF, 0x102030);
    expect(card.color!.a, closeTo(0.5, 0.01));
    final shape = card.shape as RoundedRectangleBorder;
    expect((shape.borderRadius as BorderRadius).topLeft.x, 24);
  });

  testWidgets('applies text color to the title', (tester) async {
    await _pump(tester, _def(appearance: styled));

    final title = tester.widget<Text>(find.text('Wohnzimmer'));
    final effective = DefaultTextStyle.of(
      tester.element(find.text('Wohnzimmer')),
    ).style.merge(title.style);
    expect(effective.color!.toARGB32() & 0xFFFFFF, 0xFFEEAA);
  });

  testWidgets('applies accent color to the value', (tester) async {
    await _pump(tester, _def(appearance: styled));

    final value = tester.widget<Text>(find.text('21.5'));
    expect(value.style!.color!.toARGB32() & 0xFFFFFF, 0x33CC99);
  });

  testWidgets('applies the font scale', (tester) async {
    await _pump(tester, _def(appearance: styled));

    final scaler = MediaQuery.textScalerOf(
      tester.element(find.text('Wohnzimmer')),
    );
    expect(scaler.scale(10), closeTo(15, 0.01));
  });

  testWidgets('without appearance the card looks like before', (tester) async {
    await _pump(tester, _def());

    final card = tester.widget<Card>(find.byType(Card));
    expect(card.color, isNull);
    final shape = card.shape as RoundedRectangleBorder;
    expect((shape.borderRadius as BorderRadius).topLeft.x, 16);
    final scaler = MediaQuery.textScalerOf(
      tester.element(find.text('Wohnzimmer')),
    );
    expect(scaler.scale(10), closeTo(10, 0.01));
  });
}
