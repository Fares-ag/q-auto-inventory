// lib/widgets/alerts_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/local_data_store.dart';
import 'package:provider/provider.dart';

// Simple Alert model class for holding alert data
class Alert {
  final String title; // Title of the alert
  final String message; // Detailed message of the alert
  final DateTime timestamp; // When the alert was generated
  final IconData icon; // Icon representing the type of alert
  final Color iconColor; // Color of the alert icon

  Alert({
    required this.title,
    required this.message,
    required this.timestamp,
    required this.icon,
    required this.iconColor,
  });
}

// Main Alerts Screen widget
class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  // Hardcoded dummy alerts for the prototype/demo
  final List<Alert> _alerts = [
    Alert(
      title: 'Maintenance Due!',
      message: 'The HP 27" Monitor in IT needs maintenance in 3 days.',
      timestamp: DateTime.now(),
      icon: Icons.build_circle_outlined,
      iconColor: Colors.orange,
    ),
    Alert(
      title: 'Item Submitted',
      message:
          'A new Mechanical Keyboard has been submitted for your approval.',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      icon: Icons.playlist_add_check,
      iconColor: Colors.blue,
    ),
    Alert(
      title: 'Low Stock Alert',
      message: 'You are running low on Office Chairs. Please order more.',
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      icon: Icons.warning_amber_outlined,
      iconColor: Colors.red,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // App bar at the top
      appBar: AppBar(
        title: const Text('Alerts'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),

      // If no alerts, show placeholder text, otherwise list alerts
      body: _alerts.isEmpty
          ? const Center(child: Text('No new alerts.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _alerts.length,
              itemBuilder: (context, index) {
                final alert = _alerts[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16.0),
                  child: ListTile(
                    // Leading icon inside a circle background
                    leading: CircleAvatar(
                      backgroundColor: alert.iconColor.withOpacity(0.1),
                      child: Icon(alert.icon, color: alert.iconColor),
                    ),
                    // Alert title
                    title: Text(alert.title,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    // Alert message
                    subtitle: Text(alert.message),
                    // Display alert timestamp (hour:minute)
                    trailing: Text(
                        '${alert.timestamp.hour}:${alert.timestamp.minute.toString().padLeft(2, '0')}'),
                    // On tap, show a snackbar with the alert title
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Tapped on alert: ${alert.title}'),
                      ));
                    },
                  ),
                );
              },
            ),
    );
  }
}
