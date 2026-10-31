import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sensor_widgets/app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App starts and loads initial dashboard', (tester) async {
    await tester.pumpWidget(const SensorWidgetsApp());
    await tester.pumpAndSettle();

    expect(find.text('Sensor Widgets'), findsOneWidget);
  });
}
