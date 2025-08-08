import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/item_model.dart';
import 'package:flutter_application_1/widgets/items_detail.dart';
import 'package:flutter_application_1/widgets/item_model.dart'; // Add this import

// This screen displays the full list of items with filtering and search capabilities.
class FilteredItemsScreen extends StatefulWidget {
  final List<ItemModel> items;

  const FilteredItemsScreen({
    Key? key,
    required this.items,
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
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ItemDetailsScreen(item: item),
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
                ],
              ),
            ),
            if (item.isTagged)
              const Icon(Icons.label, color: Colors.blue, size: 20),
            const SizedBox(width: 8),
            if (item.isWrittenOff)
              const Icon(Icons.delete_forever, color: Colors.red, size: 20),
          ],
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
