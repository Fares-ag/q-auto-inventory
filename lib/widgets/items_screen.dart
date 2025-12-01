import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/add_item.dart';
import 'package:flutter_application_1/models/item_model.dart';
import 'package:flutter_application_1/widgets/filtered_items_screen.dart';
import 'package:flutter_application_1/widgets/items_detail.dart';
import 'package:flutter_application_1/config/app_theme.dart';

class ItemsScreen extends StatefulWidget {
  final List<ItemModel> items;
  final Function(ItemModel) onUpdateItem;
  final Function(ItemModel) navigateToItemDetails;

  const ItemsScreen({
    super.key,
    required this.items,
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
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: ShaderMask(
              shaderCallback: (bounds) =>
                  AppTheme.primaryGradient.createShader(bounds),
              child: const Text(
                'Items',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
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
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
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
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(ItemModel item) {
    // Determine status badge color
    Color statusBadgeColor = const Color(0xFFD1FAE5); // Light green
    Color statusTextColor = const Color(0xFF065F46); // Dark green
    String statusText = item.status ?? 'Operational';

    if (item.status == 'Maintenance') {
      statusBadgeColor = const Color(0xFFFEF3C7); // Light yellow
      statusTextColor = const Color(0xFF92400E); // Dark yellow
    } else if (item.status == 'Offline') {
      statusBadgeColor = const Color(0xFFFEE2E2); // Light red
      statusTextColor = const Color(0xFF991B1B); // Dark red
    }

    return GestureDetector(
      onTap: () => widget.navigateToItemDetails(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.softShadow,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Small image box / icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppTheme.backgroundColor,
              ),
              clipBehavior: Clip.antiAlias,
              child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                  ? Image.network(
                      item.imageUrl!,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      decoration: const BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      child: Center(child: buildItemIcon(item.itemType)),
                    ),
            ),
            const SizedBox(width: 16),
            // Right side content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: Title and Status Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title
                            Text(
                              item.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            // Sub-details
                            Text(
                              item.category,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            if (item.location != null ||
                                item.utilization != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                [
                                  item.location,
                                  item.utilization != null
                                      ? '${item.utilization}% utilization'
                                      : null,
                                ].where((e) => e != null).join(' • '),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: statusBadgeColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: statusTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Bottom row: Condition, Next Event, and Action Icons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Condition
                      if (item.condition != null)
                        Text(
                          'Condition: ${item.condition}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF1E293B),
                          ),
                        )
                      else
                        const SizedBox.shrink(),
                      const Spacer(),
                      // Next Event Date
                      if (item.nextEventDate != null)
                        Text(
                          'Next: ${item.nextEventDate}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      const SizedBox(width: 16),
                      // Action Icons
                      Row(
                        children: [
                          _buildActionIconButton(
                            icon: Icons.visibility_outlined,
                            color: const Color(0xFFEF4444),
                            onTap: () => widget.navigateToItemDetails(item),
                          ),
                          const SizedBox(width: 8),
                          _buildActionIconButton(
                            icon: Icons.edit_outlined,
                            color: const Color(0xFF3B82F6),
                            onTap: () => widget.navigateToItemDetails(item),
                          ),
                          const SizedBox(width: 8),
                          _buildActionIconButton(
                            icon: Icons.build_outlined,
                            color: const Color(0xFF10B981),
                            onTap: () => widget.navigateToItemDetails(item),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }

  Widget buildItemIcon(ItemType type) {
    switch (type) {
      case ItemType.laptop:
        return const Icon(Icons.laptop_mac, size: 30, color: Colors.white);
      case ItemType.keyboard:
        return const Icon(Icons.keyboard, size: 30, color: Colors.white);
      case ItemType.furniture:
        return const Icon(Icons.chair, size: 30, color: Colors.white);
      case ItemType.monitor:
        return const Icon(Icons.monitor, size: 30, color: Colors.white);
      case ItemType.tablet:
        return const Icon(Icons.tablet_android, size: 30, color: Colors.white);
      case ItemType.webcam:
        return const Icon(Icons.videocam, size: 30, color: Colors.white);
      default:
        return const Icon(Icons.inventory, size: 30, color: Colors.white);
    }
  }
}
