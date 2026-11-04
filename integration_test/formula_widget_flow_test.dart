import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/formula_widget_flow_test.dart' as formula_test;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // The wrapped flows assert the German texts; the device may use any language.
  setUp(() {
    binding.platformDispatcher.localesTestValue = const [Locale('de', 'DE')];
  });

  formula_test.main();
}
