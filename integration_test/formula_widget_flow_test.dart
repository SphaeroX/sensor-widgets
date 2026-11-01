import 'package:integration_test/integration_test.dart';

import '../test/formula_widget_flow_test.dart' as formula_test;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  formula_test.main();
}
