import 'package:flutter/material.dart';
import 'package:sensor_widgets/presentation/screens/dashboard/widgets_dashboard_screen.dart';

/// The root application widget for Sensor Widgets.
class SensorWidgetsApp extends StatelessWidget {
  const SensorWidgetsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sensor Widgets',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const WidgetsDashboardScreen(),
    );
  }
}
