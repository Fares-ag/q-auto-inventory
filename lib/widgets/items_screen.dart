// lib/widgets/items_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/models/item_model.dart';
import 'package:flutter_application_1/widgets/add_item.dart';
import 'package:flutter_application_1/widgets/filtered_items_screen.dart';
import 'package:flutter_application_1/widgets/items_detail.dart';
import 'package:flutter_application_1/services/local_data_store.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/widgets/bulk_assign_screen.dart';

class ItemsScreen extends StatelessWidget {
  final List<ItemModel> items;
  final Function(ItemModel) onUpdateItem;
  final Function(ItemModel) navigateToItemDetails;

  const ItemsScreen({
    super.key,
    required this.items,
    required this.onUpdateItem,
    required this.navigateToItemDetails,
  });

  void _showAddItemModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => AddItemWidget(
          onClose: () => Navigator.of(context).pop(),
          onSave: (newItem) {
            LocalDataStore().addItem(newItem);
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        title: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/logo.png', // Assuming you have a logo here
                height: 32,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(6)),
                  child:
                      const Icon(Icons.business, color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Q-AUTO',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black)),
                  Text('Digital Asset Management',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                ],
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Items',
                style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold, color: Colors.black)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(context,
                      icon: Icons.search, label: 'Search', onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => ChangeNotifierProvider.value(
                            value: Provider.of<LocalDataStore>(context,
                                listen: false),
                            child: FilteredItemsScreen(
                                items: items, onUpdateItem: onUpdateItem))));
                  }),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(context,
                      icon: Icons.add,
                      label: 'Add New',
                      onTap: () => _showAddItemModal(context)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: _buildActionButton(
                context,
                icon: Icons.inventory_2_outlined,
                label: 'Bulk Assign',
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => ChangeNotifierProvider.value(
                      value:
                          Provider.of<LocalDataStore>(context, listen: false),
                      child: const BulkAssignScreen(),
                    ),
                  ));
                },
              ),
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: Offset(0, 4))
                  ]),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${items.length} Total Items',
                          style: theme.textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => ChangeNotifierProvider.value(
                                  value: Provider.of<LocalDataStore>(context,
                                      listen: false),
                                  child: FilteredItemsScreen(
                                      items: items,
                                      onUpdateItem: onUpdateItem))));
                        },
                        child: Text('View All',
                            style: TextStyle(
                                fontSize: 16,
                                color: theme.primaryColor,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40.0),
                      child:
                          Text("No items found. Tap 'Add New' to create one."),
                    )
                  else
                    ...items
                        .take(3)
                        .map((item) => _buildItemCard(context, item))
                        .toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context,
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 2))
            ]),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.grey[800], size: 20),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[800],
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(BuildContext context, ItemModel item) {
    return GestureDetector(
      onTap: () => navigateToItemDetails(item),
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200)),
        child: Row(
          children: [
            SizedBox(
              width: 50,
              height: 50,
              child: Center(child: buildItemIcon(item.itemType)),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black)),
                  const SizedBox(height: 4),
                  Text(item.category,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}

Widget buildItemIcon(ItemType type) {
  switch (type) {
    case ItemType.laptop:
      return const Icon(Icons.laptop_mac, size: 32);
    case ItemType.keyboard:
      return const Icon(Icons.keyboard, size: 32);
    case ItemType.furniture:
      return const Icon(Icons.chair, size: 32, color: Colors.brown);
    case ItemType.monitor:
      return const Icon(Icons.monitor, size: 32);
    case ItemType.tablet:
      return const Icon(Icons.tablet_android, size: 32);
    case ItemType.webcam:
      return const Icon(Icons.videocam, size: 32);
    default:
      return const Icon(Icons.inventory, size: 32);
  }
}
