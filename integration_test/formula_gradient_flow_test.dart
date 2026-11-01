import 'package:integration_test/integration_test.dart';

import '../test/e2e_formula_gradient_flow_test.dart' as gradient_flow;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  gradient_flow.main();
}
