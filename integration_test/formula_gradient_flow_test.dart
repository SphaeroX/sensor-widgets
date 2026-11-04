import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/e2e_formula_gradient_flow_test.dart' as gradient_flow;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // The wrapped flows assert the German texts; the device may use any language.
  setUp(() {
    binding.platformDispatcher.localesTestValue = const [Locale('de', 'DE')];
  });

  gradient_flow.main();
}
