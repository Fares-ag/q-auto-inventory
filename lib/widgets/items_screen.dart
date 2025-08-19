// lib/widgets/items_screen.dart

// Import necessary packages from Flutter and other local files.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/models/item_model.dart';
import 'package:flutter_application_1/widgets/add_item.dart';
import 'package:flutter_application_1/widgets/filtered_items_screen.dart';
import 'package:flutter_application_1/widgets/items_detail.dart';
import 'package:flutter_application_1/services/local_data_store.dart';
import 'package:provider/provider.dart';

/// A stateless widget that serves as the main screen for displaying a summary of items.
/// It provides actions to search, add, and view items.
class ItemsScreen extends StatelessWidget {
  /// The list of all items to be displayed or summarized.
  final List<ItemModel> items;

  /// A callback function to update an item in the parent widget's state.
  final Function(ItemModel) onUpdateItem;

  /// A callback function to handle navigation to the details screen of a specific item.
  final Function(ItemModel) navigateToItemDetails;

  const ItemsScreen({
    super.key,
    required this.items,
    required this.onUpdateItem,
    required this.navigateToItemDetails,
  });

  /// Displays a modal bottom sheet containing the form to add a new item.
  void _showAddItemModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled:
          true, // Allows the modal to take up most of the screen height.
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.9, // The initial height of the sheet.
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => AddItemWidget(
          onClose: () => Navigator.of(context).pop(),
          onSave: (newItem) {
            // When saved, add the new item to the data store and close the modal.
            LocalDataStore().addItem(newItem);
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        systemOverlayStyle:
            SystemUiOverlayStyle.dark, // Ensures status bar icons are dark.
        title: Center(
          // Custom title widget displaying the company logo and name.
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(6)),
                child:
                    const Icon(Icons.business, color: Colors.white, size: 20),
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
                  Text('by Sawa Technologies',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                ],
              ),
            ],
          ),
        ),
        // A thin line at the bottom of the app bar to act as a separator.
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey[200], height: 1.0),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Screen Header ---
            const Text('Items',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black)),
            const SizedBox(height: 20),
            // --- Action Buttons (Search, Add) ---
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(context,
                      icon: Icons.search, label: 'Search', onTap: () {
                    // Navigate to the screen that shows all items with search/filter capabilities.
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => ChangeNotifierProvider.value(
                            value: LocalDataStore(),
                            child: FilteredItemsScreen(
                                items: items, onUpdateItem: onUpdateItem))));
                  }),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildActionButton(context,
                      icon: Icons.add,
                      label: 'Add',
                      onTap: () => _showAddItemModal(context)),
                ),
              ],
            ),
            const SizedBox(height: 30),
            // --- Items Summary Card ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${items.length} Items',
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.black)),
                      GestureDetector(
                        onTap: () {
                          // "View All" navigates to the same filtered screen as the search button.
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => ChangeNotifierProvider.value(
                                  value: LocalDataStore(),
                                  child: FilteredItemsScreen(
                                      items: items,
                                      onUpdateItem: onUpdateItem))));
                        },
                        child: Text('View All',
                            style: TextStyle(
                                fontSize: 16, color: Colors.grey[500])),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Conditionally display a message if no items exist,
                  // otherwise, display a preview of the first 3 items.
                  if (items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20.0),
                      child: Text("No items found. Tap 'Add' to create one."),
                    )
                  else
                    ...items // Use the spread operator to add the list of widgets here.
                        .take(3) // Take only the first 3 items for the preview.
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

  /// A helper method to build the styled action buttons ('Search', 'Add').
  Widget _buildActionButton(BuildContext context,
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
            color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
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

  /// A helper method to build a card widget for a single item in the list preview.
  Widget _buildItemCard(BuildContext context, ItemModel item) {
    return GestureDetector(
      // When tapped, navigate to the item's details screen.
      onTap: () => navigateToItemDetails(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: Center(child: buildItemIcon(item.itemType)),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.category,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                  const SizedBox(height: 2),
                  Text(item.name,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A helper function that returns an appropriate icon based on the [ItemType].
Widget buildItemIcon(ItemType type) {
  switch (type) {
    case ItemType.laptop:
      return const Icon(Icons.laptop_mac, size: 40);
    case ItemType.keyboard:
      return const Icon(Icons.keyboard, size: 40);
    case ItemType.furniture:
      return const Icon(Icons.chair, size: 40, color: Colors.brown);
    case ItemType.monitor:
      return const Icon(Icons.monitor, size: 40);
    case ItemType.tablet:
      return const Icon(Icons.tablet_android, size: 40);
    case ItemType.webcam:
      return const Icon(Icons.videocam, size: 40);
    default:
      return const Icon(Icons.inventory, size: 40);
  }
}
