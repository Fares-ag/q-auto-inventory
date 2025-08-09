import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/add_item.dart';
import 'package:flutter_application_1/widgets/item_model.dart';
import 'package:flutter_application_1/widgets/filtered_items_screen.dart';
import 'package:flutter_application_1/widgets/items_detail.dart';
import 'package:flutter_application_1/widgets/history_entry_model.dart';
import 'package:flutter_application_1/widgets/issue_model.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:math';

class ItemsScreen extends StatefulWidget {
  final List<ItemModel> items;
  final List<HistoryEntry> dummyHistory;
  final List<Issue> dummyIssues;
  final Function(ItemModel) onUpdateItem;
  final Function(ItemModel) navigateToItemDetails;

  const ItemsScreen({
    super.key,
    required this.items,
    required this.dummyHistory,
    required this.dummyIssues,
    required this.onUpdateItem,
    required this.navigateToItemDetails,
  });

  @override
  _ItemsScreenState createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  void _handleViewAll() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FilteredItemsScreen(
          items: widget.items,
          onUpdateItem: widget.onUpdateItem,
        ),
      ),
    );
  }

  void _handleAdd() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return AddItemWidget(
          onSave: (itemData) {
            final newItem = ItemModel(
              id: Random().nextInt(99999999).toString(),
              name: itemData.name,
              category: 'Other',
              variants: '1 Variant',
              supplier: 'Unknown',
              company: 'Unknown',
              date: 'Now',
              itemType: ItemType.laptop,
            );
            widget.onUpdateItem(newItem);
            Navigator.of(context).pop();
          },
          onClose: () {
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  // NOTE: This scan function is local to this page's buttons.
  // The main FAB scan is handled in root_screen.dart.
  void _handleScan() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => QRScannerPage(
          onScan: (scannedCode) {
            ItemModel? foundItem;
            try {
              foundItem = widget.items.firstWhere(
                (item) => item.qrCodeId == scannedCode,
              );
            } catch (e) {
              foundItem = null;
            }

            if (foundItem != null) {
              widget.navigateToItemDetails(foundItem);
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Item with this QR code not found.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // REMOVED the Scaffold, AppBar, and bottomNavigationBar.
    // Return only the body content.
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 20),
            child: Text(
              'Items',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.qr_code_scanner,
                  label: 'Scan',
                  onTap: _handleScan,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.search,
                  label: 'Search',
                  onTap: _handleViewAll,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.add,
                  label: 'Add',
                  onTap: _handleAdd,
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${widget.items.length} Items',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    GestureDetector(
                      onTap: _handleViewAll,
                      child: Text(
                        'View All',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[500],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ...widget.items
                    .take(3)
                    .map((item) => _buildItemCard(item))
                    .toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.grey[800], size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[800],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(ItemModel item) {
    return GestureDetector(
      onTap: () {
        widget.navigateToItemDetails(item);
      },
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
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: buildItemIcon(item.itemType),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.category,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.variants,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                  // Additional details can be added here if needed
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildItemIcon(ItemType type) {
    switch (type) {
      case ItemType.laptop:
        return const Icon(Icons.laptop_mac, size: 30, color: Colors.black87);
      case ItemType.keyboard:
        return const Icon(Icons.keyboard, size: 30, color: Colors.black87);
      case ItemType.furniture:
        return const Icon(Icons.chair, size: 30, color: Colors.brown);
      case ItemType.monitor:
        return const Icon(Icons.monitor, size: 30, color: Colors.black87);
      case ItemType.tablet:
        return const Icon(Icons.tablet_android,
            size: 30, color: Colors.blueGrey);
      case ItemType.webcam:
        return const Icon(Icons.videocam, size: 30, color: Colors.grey);
      default:
        return const Icon(Icons.inventory, size: 30, color: Colors.black87);
    }
  }
}
