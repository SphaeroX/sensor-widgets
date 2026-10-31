import 'package:flutter/material.dart';
import 'package:sensor_widgets/presentation/screens/connections/connections_list_screen.dart';

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
      home: const DashboardHomeScreen(),
    );
  }
}

/// Main dashboard shell offering navigation between widgets and connections.
class DashboardHomeScreen extends StatelessWidget {
  const DashboardHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sensor Widgets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_ethernet),
            tooltip: 'InfluxDB Connections',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ConnectionsListScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: const ConnectionsListScreen(),
    );
  }
}
