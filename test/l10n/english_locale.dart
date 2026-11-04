import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Simulates an English device for every test of the calling file
/// (overrides the German default of `test/flutter_test_config.dart`).
void useEnglishDeviceLocale() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized()
        .platformDispatcher
        .localesTestValue = const [
      Locale('en', 'US'),
    ];
  });
}
