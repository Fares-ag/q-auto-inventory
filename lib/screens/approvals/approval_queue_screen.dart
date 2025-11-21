import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/firestore_models.dart';
import '../../services/firebase_services.dart';
import '../../widgets/permission_guard.dart';
import '../../widgets/skeleton_list.dart';

class ApprovalQueueScreen extends StatelessWidget {
  const ApprovalQueueScreen({super.key});

  Future<void> _handleDecision(
    BuildContext context,
    CatalogService catalog,
    InventoryItem item,
    bool approve,
  ) async {
    final status = approve ? 'active' : 'rejected';
    await catalog.updateItemStatus(item.id, status);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(approve ? 'Approved ${item.name}' : 'Rejected ${item.name}'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogService>();
    return Scaffold(
      appBar: AppBar(title: const Text('Approval Queue')),
      body: ItemManagementOnly(
        showError: true,
        child: StreamBuilder<List<InventoryItem>>(
        stream: catalog.watchItems(status: 'pending'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: SkeletonList(itemCount: 10, itemHeight: 72),
            );
          }
          if (snapshot.hasError) {
            return Center(child: Text('Failed to load approvals: ${snapshot.error}'));
          }
          final items = snapshot.data ?? const [];
          if (items.isEmpty) {
            return const Center(child: Text('No items awaiting approval.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.pending_actions_outlined, color: Colors.orange),
                  title: Text(item.name),
                  subtitle: Text('Category: ${item.categoryId}\nSubmitted: ${item.purchaseDate?.toString().split(' ').first ?? 'N/A'}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check_circle, color: Colors.green),
                        onPressed: () => _handleDecision(context, catalog, item, true),
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        onPressed: () => _handleDecision(context, catalog, item, false),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      ),
    );
  }
}
