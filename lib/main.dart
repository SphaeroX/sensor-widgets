import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensor_widgets/app.dart';

void main() {
  runZonedGuarded(
    () {
      WidgetsFlutterBinding.ensureInitialized();
      FlutterError.onError = (details) {
        FlutterError.presentError(details);
      };
      runApp(const ProviderScope(child: SensorWidgetsApp()));
    },
    (error, stack) {
      debugPrint('Uncaught Flutter error: $error\n$stack');
    },
  );
}
