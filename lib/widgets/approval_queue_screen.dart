// lib/widgets/approval_queue_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/item_model.dart';
import 'package:flutter_application_1/services/local_data_store.dart';
import 'package:flutter_application_1/widgets/items_detail.dart';
import 'package:provider/provider.dart';

// Screen that shows items pending approval
class ApprovalQueueScreen extends StatelessWidget {
  const ApprovalQueueScreen({Key? key}) : super(key: key);

  // Helper function: Approves all pending items in bulk
  void _bulkApprove(BuildContext context) {
    final dataStore = Provider.of<LocalDataStore>(context, listen: false);
    final pendingItems =
        dataStore.items.where((item) => item.isPending).toList();

    // If no items are pending, show info message
    if (pendingItems.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('No items to approve.')));
      return;
    }

    // Approve each pending item
    for (var item in pendingItems) {
      dataStore.approveItem(item.id);
    }

    // Show confirmation after bulk approval
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${pendingItems.length} items approved!')));
  }

  @override
  Widget build(BuildContext context) {
    // Access LocalDataStore from Provider
    final dataStore = Provider.of<LocalDataStore>(context);
    // Filter out only items that are still pending
    final pendingItems =
        dataStore.items.where((item) => item.isPending).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Approval Queue'),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          // Bulk approve button in the app bar
          IconButton(
            icon: const Icon(Icons.playlist_add_check),
            onPressed: () => _bulkApprove(context),
            tooltip: 'Bulk Approve All',
          ),
        ],
      ),

      // If no items are pending, show a placeholder message
      body: pendingItems.isEmpty
          ? const Center(child: Text('No items pending approval.'))
          : ListView.builder(
              itemCount: pendingItems.length,
              itemBuilder: (context, index) {
                final item = pendingItems[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    // Leading pending icon
                    leading: Icon(Icons.pending_actions,
                        color: Colors.orange.shade700),

                    // Item name
                    title: Text(item.name),

                    // Show category and submitted date
                    subtitle: Text(
                        'Category: ${item.category} | Submitted: ${item.purchaseDate.toLocal().toString().split(' ')[0]}'),

                    // Action buttons (approve / reject)
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Approve button
                        IconButton(
                          icon: const Icon(Icons.check_circle_outline,
                              color: Colors.green),
                          onPressed: () {
                            dataStore.approveItem(item.id);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text('${item.name} approved!')));
                          },
                        ),
                        // Reject button
                        IconButton(
                          icon: const Icon(Icons.cancel_outlined,
                              color: Colors.red),
                          onPressed: () {
                            dataStore.rejectItem(item.id);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text('${item.name} rejected!')));
                          },
                        ),
                      ],
                    ),

                    // Tapping opens full item details screen
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => ChangeNotifierProvider.value(
                          value: dataStore,
                          child: ItemDetailsScreen(
                            item: item,
                            onUpdateItem: dataStore.updateItem,
                          ),
                        ),
                      ));
                    },
                  ),
                );
              },
            ),
    );
  }
}
