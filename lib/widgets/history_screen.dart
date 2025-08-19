// lib/widgets/history_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/local_data_store.dart';
import 'package:flutter_application_1/models/history_entry_model.dart';

/// Screen to display all historical actions or events in the app.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Retrieve all history entries from LocalDataStore and reverse to show latest first
    final historyEntries = LocalDataStore().history.reversed.toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with title and close button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('History',
                      style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w600,
                          color: Colors.black)),
                  Container(
                    decoration: BoxDecoration(
                        color: Colors.grey[100], shape: BoxShape.circle),
                    child: IconButton(
                      onPressed: () =>
                          Navigator.pop(context), // Close history screen
                      icon: const Icon(Icons.close, color: Colors.grey),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              // Expanded list of history entries or empty state
              Expanded(
                child: historyEntries.isEmpty
                    ? const Center(
                        child: Text('No history entries found.'),
                      )
                    : ListView.builder(
                        itemCount: historyEntries.length,
                        itemBuilder: (context, index) {
                          final entry = historyEntries[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 32.0),
                            child: _buildHistoryEntry(
                                entry), // Build each entry row
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Widget to display a single history entry with icon, title, description, and timestamp
  Widget _buildHistoryEntry(HistoryEntry entry) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon for the history entry
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
          child:
              Icon(entry.icon ?? Icons.history, size: 24, color: Colors.blue),
        ),
        const SizedBox(width: 16),
        // Textual details of the history entry
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Entry title
              Text(entry.title,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black)),
              const SizedBox(height: 8),
              // Entry description
              Text(entry.description,
                  style: TextStyle(
                      fontSize: 16, color: Colors.grey[600], height: 1.3)),
              const SizedBox(height: 8),
              // Entry timestamp formatted as DD/MM/YYYY
              Text(
                  '${entry.timestamp.day}/${entry.timestamp.month}/${entry.timestamp.year}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500])),
            ],
          ),
        ),
      ],
    );
  }
}
