import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/firestore_models.dart';
import '../../services/firebase_services.dart';

class ActivityHistoryScreen extends StatelessWidget {
  const ActivityHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Activity History')),
      body: FutureBuilder<List<HistoryEntry>>(
        future: context.read<HistoryService>().recentHistory(limit: 50),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Failed to load history: ${snapshot.error}'));
          }
          final entries = snapshot.data ?? const [];
          if (entries.isEmpty) {
            return const Center(child: Text('No recent activity.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final entry = entries[index];
              return ListTile(
                leading: const Icon(Icons.refresh),
                title: Text(entry.action),
                subtitle: Text(entry.notes ?? entry.itemId),
                trailing: Text(
                  entry.timestamp?.toLocal().toString().substring(0, 10) ?? '',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              );
            },
            separatorBuilder: (_, __) => const Divider(),
            itemCount: entries.length,
          );
        },
      ),
    );
  }
}
