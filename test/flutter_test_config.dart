import 'dart:async';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

/// Runs before every test file in `test/`.
///
/// The app follows the device language and falls back to English. Most
/// widget tests assert the German texts, so the simulated device language is
/// German unless a test sets its own (see `test/l10n/app_locale_test.dart`).
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized()
        .platformDispatcher
        .localesTestValue = const [
      Locale('de', 'DE'),
    ];
  });
  await testMain();
}
