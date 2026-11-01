import 'package:flutter/material.dart';
import 'package:sensor_widgets/core/theme/app_theme.dart';
import 'package:sensor_widgets/presentation/screens/dashboard/widgets_dashboard_screen.dart';

/// The root application widget for Sensor Widgets.
///
/// Uses the Material 3 light/dark themes and follows the system brightness.
class SensorWidgetsApp extends StatelessWidget {
  /// Start screen; defaults to the dashboard (overridable for tests).
  final Widget home;

  const SensorWidgetsApp({
    super.key,
    this.home = const WidgetsDashboardScreen(),
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sensor Widgets',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: home,
    );
  }
}
