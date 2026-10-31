import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensor_widgets/app.dart';

void main() {
  testWidgets('SensorWidgetsApp renders without crashing and shows title', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: SensorWidgetsApp()));

    expect(find.text('Sensor Widgets'), findsOneWidget);
  });
}
