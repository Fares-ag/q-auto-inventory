// lib/widgets/filtered_items_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/item_model.dart';
import 'package:flutter_application_1/widgets/items_detail.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/services/local_data_store.dart';

/// Defines the available options for the status filter.
enum ItemStatusFilter { all, available, inUse, writtenOff, untagged }

/// A screen that displays a list of items with search and advanced filtering capabilities.
class FilteredItemsScreen extends StatefulWidget {
  /// The complete list of items to be filtered and displayed.
  final List<ItemModel> items;

  /// A callback function to update an item's state in the parent widget.
  final Function(ItemModel) onUpdateItem;

  /// Optional initial filters to apply when the screen is first loaded.
  final Map<String, String>? initialFilters;

  const FilteredItemsScreen({
    Key? key,
    required this.items,
    required this.onUpdateItem,
    this.initialFilters,
  }) : super(key: key);

  @override
  State<FilteredItemsScreen> createState() => _FilteredItemsScreenState();
}

class _FilteredItemsScreenState extends State<FilteredItemsScreen> {
  /// Controller for the search text field.
  final TextEditingController _searchController = TextEditingController();

  /// The list of items currently displayed after applying filters and search.
  late List<ItemModel> _filteredItems;

  /// Sets to hold unique filter options collected from the item list.
  final Set<String> _departments = {};
  final Set<String> _categories = {};
  final Set<String> _staff = {};

  /// A map that stores the current state of the selected filters.
  Map<String, dynamic> _filterOptions = {
    'status': ItemStatusFilter.all,
    'department': 'All',
    'category': 'All',
    'assignedStaff': 'All',
  };

  @override
  void initState() {
    super.initState();
    // Populate the filter options from the list of all items.
    _collectAllOptions();
    // If initial filters were provided, apply them.
    if (widget.initialFilters != null) {
      _filterOptions = _applyInitialFilters(widget.initialFilters!);
    }
    // Perform the initial filtering of items.
    _applyFilters();
    // Add a listener to the search controller to re-apply filters on text change.
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    // Clean up the controller and listener to prevent memory leaks.
    _searchController.removeListener(_applyFilters);
    _searchController.dispose();
    super.dispose();
  }

  /// Merges externally provided initial filters with the default filter options.
  Map<String, dynamic> _applyInitialFilters(
      Map<String, String> initialFilters) {
    final newOptions = Map<String, dynamic>.from(_filterOptions);
    initialFilters.forEach((key, value) {
      if (newOptions.containsKey(key)) {
        newOptions[key] = value;
      }
    });
    return newOptions;
  }

  /// Iterates through all items to collect unique values for filter dropdowns.
  void _collectAllOptions() {
    for (var item in widget.items) {
      if (item.department != null) _departments.add(item.department!);
      _categories.add(item.category);
      if (item.assignedStaff != null) _staff.add(item.assignedStaff!);
    }
  }

  /// The core logic for filtering the item list based on selected options and search query.
  void _applyFilters() {
    // Start with the full list and apply the advanced filters.
    List<ItemModel> tempFilteredList = widget.items.where((item) {
      final statusFilter = _filterOptions['status'] as ItemStatusFilter;
      final deptFilter = _filterOptions['department'] as String;
      final categoryFilter = _filterOptions['category'] as String;
      final staffFilter = _filterOptions['assignedStaff'] as String;

      // Check status match.
      bool statusMatch = true;
      switch (statusFilter) {
        case ItemStatusFilter.all:
          statusMatch = true;
          break;
        case ItemStatusFilter.available:
          statusMatch = item.isAvailable && !item.isWrittenOff;
          break;
        case ItemStatusFilter.inUse:
          statusMatch = !item.isAvailable && !item.isWrittenOff;
          break;
        case ItemStatusFilter.writtenOff:
          statusMatch = item.isWrittenOff;
          break;
        case ItemStatusFilter.untagged:
          statusMatch = !item.isTagged;
          break;
      }

      // Check other filter matches.
      final departmentMatch =
          deptFilter == 'All' || item.department == deptFilter;
      final categoryMatch =
          categoryFilter == 'All' || item.category == categoryFilter;
      final staffMatch =
          staffFilter == 'All' || item.assignedStaff == staffFilter;

      // An item is included if it matches all active filters.
      return statusMatch && departmentMatch && categoryMatch && staffMatch;
    }).toList();

    // Apply the text search query to the already filtered list.
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredItems = query.isEmpty
          ? tempFilteredList
          : tempFilteredList
              .where((item) => item.name.toLowerCase().contains(query))
              .toList();
    });
  }

  /// A callback passed to the details screen to update an item and refresh the list.
  void _updateItemAndRefresh(ItemModel updatedItem) {
    widget.onUpdateItem(updatedItem);
    _applyFilters(); // Re-run filters to reflect any changes.
  }

  /// Displays a modal bottom sheet with advanced filter options.
  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Advanced Filters',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    _buildFilterSection(
                      title: 'Status',
                      options: {
                        'All': ItemStatusFilter.all,
                        'Available': ItemStatusFilter.available,
                        'In Use': ItemStatusFilter.inUse,
                        'Written Off': ItemStatusFilter.writtenOff,
                        'Untagged': ItemStatusFilter.untagged,
                      },
                      currentValue: _filterOptions['status'],
                      onChanged: (value) =>
                          setModalState(() => _filterOptions['status'] = value),
                    ),
                    _buildFilterSection(
                      title: 'Department',
                      options: {
                        'All': 'All',
                        for (var d in _departments) d: d,
                      },
                      currentValue: _filterOptions['department'],
                      onChanged: (value) => setModalState(
                          () => _filterOptions['department'] = value),
                    ),
                    _buildFilterSection(
                      title: 'Category',
                      options: {
                        'All': 'All',
                        for (var c in _categories) c: c,
                      },
                      currentValue: _filterOptions['category'],
                      onChanged: (value) => setModalState(
                          () => _filterOptions['category'] = value),
                    ),
                    _buildFilterSection(
                      title: 'Assigned Staff',
                      options: {
                        'All': 'All',
                        for (var s in _staff) s: s,
                      },
                      currentValue: _filterOptions['assignedStaff'],
                      onChanged: (value) => setModalState(
                          () => _filterOptions['assignedStaff'] = value),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12))),
                        onPressed: () {
                          _applyFilters();
                          Navigator.of(context).pop();
                        },
                        child: const Text('Apply Filters',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterSection({
    required String title,
    required Map options,
    required dynamic currentValue,
    required Function(dynamic) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.entries.map((entry) {
            bool isSelected = entry.value == currentValue;
            return ChoiceChip(
              label: Text(entry.key.toString()),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  onChanged(entry.value);
                }
              },
              selectedColor: Colors.black,
              labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                  fontWeight: FontWeight.w500),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                      color: isSelected ? Colors.black : Colors.grey.shade300)),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.grey[100],
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
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_alt, color: Colors.black),
            onPressed: _showFilterModal,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by item name',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => _searchController.clear(),
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
            Expanded(
              child: _filteredItems.isEmpty
                  ? const Center(child: Text("No items match your search."))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
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

  Widget _buildItemCard(ItemModel item) {
    return GestureDetector(
      onTap: () {
        final dataStore = Provider.of<LocalDataStore>(context, listen: false);
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => ChangeNotifierProvider.value(
            value: dataStore,
            child: ItemDetailsScreen(
              item: item,
              onUpdateItem: _updateItemAndRefresh,
            ),
          ),
        ));
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8)),
                child: Center(child: buildItemIcon(item.itemType)),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                        'Dept: ${item.department ?? 'N/A'} | Assigned: ${item.assignedStaff ?? 'N/A'}',
                        style:
                            TextStyle(fontSize: 14, color: Colors.grey[600])),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                children: [
                  if (item.isTagged)
                    const Icon(Icons.label, color: Colors.blue, size: 20),
                  if (item.isWrittenOff)
                    const Icon(Icons.delete_forever,
                        color: Colors.red, size: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget buildItemIcon(ItemType type) {
  IconData iconData;
  Color color;
  switch (type) {
    case ItemType.laptop:
      iconData = Icons.laptop_mac;
      color = Colors.black87;
      break;
    case ItemType.keyboard:
      iconData = Icons.keyboard;
      color = Colors.black87;
      break;
    case ItemType.furniture:
      iconData = Icons.chair;
      color = Colors.brown;
      break;
    case ItemType.monitor:
      iconData = Icons.monitor;
      color = Colors.black87;
      break;
    case ItemType.tablet:
      iconData = Icons.tablet_android;
      color = Colors.black87;
      break;
    case ItemType.webcam:
      iconData = Icons.videocam;
      color = Colors.black87;
      break;
    default:
      iconData = Icons.inventory;
      color = Colors.grey;
  }
  return Icon(iconData, size: 32, color: color);
}
