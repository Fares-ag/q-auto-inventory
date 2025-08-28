// lib/widgets/bulk_item_import_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/item_model.dart';
import 'package:flutter_application_1/services/local_data_store.dart';
import 'package:provider/provider.dart';

class BulkItemImportScreen extends StatefulWidget {
  const BulkItemImportScreen({super.key});

  @override
  State<BulkItemImportScreen> createState() => _BulkItemImportScreenState();
}

class _BulkItemImportScreenState extends State<BulkItemImportScreen> {
  bool _isLoading = false; // Tracks whether import is in progress

  // Dummy CSV-like data to simulate a file import
  final List<Map<String, dynamic>> _dummyCsvData = [
    {
      'ID': 'item_101',
      'Name': 'Dell XPS 15',
      'Category': 'Laptop',
      'Item Type': 'laptop',
      'Purchase Date': '15-Jan-2023',
      'Variants': '8GB RAM, 256GB SSD',
      'Supplier': 'Dell',
      'Company': 'Sawa Technologies',
      'Department': 'IT',
      'Purchase Price': '1800.00',
      'Assigned Staff': 'N/A'
    },
    {
      'ID': 'item_102',
      'Name': 'Logitech MX Master 3',
      'Category': 'Mouse',
      'Item Type': 'other',
      'Purchase Date': '20-Feb-2023',
      'Variants': 'Graphite',
      'Supplier': 'Logitech',
      'Company': 'Sawa Technologies',
      'Department': 'Marketing',
      'Purchase Price': '120.00',
      'Assigned Staff': 'N/A'
    },
    {
      'ID': 'item_103',
      'Name': 'Herman Miller Chair',
      'Category': 'Furniture',
      'Item Type': 'furniture',
      'Purchase Date': '10-May-2022',
      'Variants': 'Black Leather',
      'Supplier': 'Herman Miller',
      'Company': 'Sawa Technologies',
      'Department': 'Operations',
      'Purchase Price': '1100.00',
      'Assigned Staff': 'N/A'
    },
    {
      'ID': 'item_104',
      'Name': 'HP 27" Monitor',
      'Category': 'Monitor',
      'Item Type': 'monitor',
      'Purchase Date': '01-Mar-2023',
      'Variants': '4K Display',
      'Supplier': 'HP',
      'Company': 'Sawa Technologies',
      'Department': 'IT',
      'Purchase Price': '350.00',
      'Assigned Staff': 'N/A'
    },
  ];

  // Starts the import simulation
  void _startImport() {
    setState(() => _isLoading = true);

    // Convert dummy data into ItemModel objects
    final List<ItemModel> newItems = _dummyCsvData.map((data) {
      // Helper: parse both ISO and custom date formats
      DateTime parseDate(String dateString) {
        try {
          // First, try ISO format (yyyy-MM-dd)
          return DateTime.parse(dateString);
        } catch (_) {
          // Otherwise parse dd-MMM-yyyy
          final parts = dateString.split('-');
          final day = int.parse(parts[0]);
          final month = _monthToNumber(parts[1]);
          final year = int.parse(parts[2]);
          return DateTime(year, month, day);
        }
      }

      return ItemModel(
        id: data['ID']!,
        name: data['Name']!,
        category: data['Category']!,
        itemType: ItemType.values.firstWhere(
          (e) =>
              e.name.toLowerCase() ==
              data['Item Type'].toString().toLowerCase(),
          orElse: () => ItemType.other,
        ),
        purchaseDate: parseDate(data['Purchase Date']!),
        variants: data['Variants']!,
        supplier: data['Supplier']!,
        company: data['Company']!,
        department: data['Department'],
        assignedStaff:
            data['Assigned Staff'] == 'N/A' ? null : data['Assigned Staff'],
        purchasePrice: double.tryParse(data['Purchase Price']!),
        status: 'approved', // Default status for imported items
        isTagged: false,
        isAvailable: true,
      );
    }).toList();

    // Simulate short delay to mimic file processing
    Future.delayed(const Duration(seconds: 1), () {
      final dataStore = Provider.of<LocalDataStore>(context, listen: false);
      dataStore.addItemsBulk(newItems);

      setState(() => _isLoading = false);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text('${newItems.length} items imported successfully (prototype)!'),
        backgroundColor: Colors.green,
      ));

      // Go back to previous screen after import
      Navigator.of(context).pop();
    });
  }

  // Converts month abbreviation (e.g., "Jan") into number
  int _monthToNumber(String month) {
    const months = {
      'Jan': 1,
      'Feb': 2,
      'Mar': 3,
      'Apr': 4,
      'May': 5,
      'Jun': 6,
      'Jul': 7,
      'Aug': 8,
      'Sep': 9,
      'Oct': 10,
      'Nov': 11,
      'Dec': 12,
    };
    return months[month] ?? 1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bulk Import Assets'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instruction text
            Text(
              'Click the button below to simulate importing a CSV file with dummy data.',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            const SizedBox(height: 20),

            // Fake "file preview" card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Simulated File: assets.csv',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ),

            const Spacer(),

            // Import button (with loading state)
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _startImport,
                icon: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : const Icon(Icons.upload),
                label: Text(_isLoading ? 'Importing...' : 'Start Import'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
