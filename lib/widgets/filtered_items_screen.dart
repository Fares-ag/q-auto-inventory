import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/item_model.dart';
import 'package:flutter_application_1/widgets/items_detail.dart';

// This screen displays the full list of items with filtering and search capabilities.
class FilteredItemsScreen extends StatefulWidget {
  final List<ItemModel> items;
  final Function(ItemModel) onUpdateItem;

  const FilteredItemsScreen({
    Key? key,
    required this.items,
    required this.onUpdateItem,
  }) : super(key: key);

  @override
  State<FilteredItemsScreen> createState() => _FilteredItemsScreenState();
}

class _FilteredItemsScreenState extends State<FilteredItemsScreen> {
  // A copy of the original list to preserve it during filtering.
  late List<ItemModel> _filteredItems;
  // The current filter selected by the user.
  ItemFilter _selectedFilter = ItemFilter.all;
  // Controller for the search text field.
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize with all items and add a listener for search text changes.
    _filteredItems = List.from(widget.items);
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    // Clean up the controller and its listener.
    _searchController.removeListener(_applyFilters);
    _searchController.dispose();
    super.dispose();
  }

  // This is the core filtering and searching logic.
  void _applyFilters() {
    // Filter the original list based on the selected filter.
    List<ItemModel> tempFilteredList = widget.items.where((item) {
      switch (_selectedFilter) {
        case ItemFilter.all:
          return true; // Show all items.
        case ItemFilter.tagged:
          return item.isTagged;
        case ItemFilter.untagged:
          return !item.isTagged;
        case ItemFilter.seenToday:
          return item.isSeenToday;
        case ItemFilter.unseen:
          return !item.isSeenToday;
        case ItemFilter.writtenOff:
          return item.isWrittenOff;
        default:
          return true;
      }
    }).toList();

    // Now apply the search query on the filtered list.
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredItems = tempFilteredList;
      } else {
        _filteredItems = tempFilteredList.where((item) {
          final nameLower = item.name.toLowerCase();
          return nameLower.contains(query);
        }).toList();
      }
    });
  }

  void _updateItemAndFilter(ItemModel updatedItem) {
    widget.onUpdateItem(updatedItem);
    _applyFilters();
  }

  // Helper function to build a filter button.
  Widget _buildFilterButton(ItemFilter filter, String label) {
    bool isSelected = _selectedFilter == filter;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filter;
          _applyFilters();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // Helper function to build each item card.
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
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ItemDetailsScreen(
              item: item,
              onUpdateItem: _updateItemAndFilter,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
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
                color: Colors.grey[100],
              ),
              clipBehavior: Clip.antiAlias,
              child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                  ? Image.network(
                      item.imageUrl!,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.indigo.shade500,
                            Colors.purple.shade500,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.inventory_2_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
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
                          // View button (red)
                          _buildActionIconButton(
                            icon: Icons.visibility_outlined,
                            color: const Color(0xFFEF4444),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => ItemDetailsScreen(
                                    item: item,
                                    onUpdateItem: _updateItemAndFilter,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          // Edit button (blue)
                          _buildActionIconButton(
                            icon: Icons.edit_outlined,
                            color: const Color(0xFF3B82F6),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => ItemDetailsScreen(
                                    item: item,
                                    onUpdateItem: _updateItemAndFilter,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          // Maintenance button (green)
                          _buildActionIconButton(
                            icon: Icons.build_outlined,
                            color: const Color(0xFF10B981),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => ItemDetailsScreen(
                                    item: item,
                                    onUpdateItem: _updateItemAndFilter,
                                  ),
                                ),
                              );
                            },
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        elevation: 0,
        title: const Text(
          'All Items',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by item name',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterButton(ItemFilter.all, 'All'),
                    const SizedBox(width: 10),
                    _buildFilterButton(ItemFilter.tagged, 'Tagged'),
                    const SizedBox(width: 10),
                    _buildFilterButton(ItemFilter.untagged, 'Untagged'),
                    const SizedBox(width: 10),
                    _buildFilterButton(ItemFilter.seenToday, 'Seen Today'),
                    const SizedBox(width: 10),
                    _buildFilterButton(ItemFilter.unseen, 'Unseen'),
                    const SizedBox(width: 10),
                    _buildFilterButton(ItemFilter.writtenOff, 'Written Off'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                itemCount: _filteredItems.length,
                itemBuilder: (context, index) {
                  final item = _filteredItems[index];
                  return _buildItemCard(item);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
