import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/item_model.dart';
import 'package:flutter_application_1/services/local_data_store.dart';
import 'package:provider/provider.dart';

/// Main screen for building a custom report by selecting desired fields.
class CustomReportBuilderScreen extends StatefulWidget {
  const CustomReportBuilderScreen({super.key});

  @override
  State<CustomReportBuilderScreen> createState() =>
      _CustomReportBuilderScreenState();
}

class _CustomReportBuilderScreenState extends State<CustomReportBuilderScreen> {
  /// Map to keep track of which fields are selected for the report.
  /// Default selections: ID, Name, Category, Department, Assigned Staff, Purchase Price.
  final Map<String, bool> _selectedFields = {
    'ID': true,
    'Name': true,
    'Category': true,
    'Department': true,
    'Assigned Staff': true,
    'Purchase Price': true,
    'Purchase Date': false,
    'Current Value': false,
    'Status': false,
    'SAP Class': false,
    'APC Acct': false,
    'Asset Class Desc': false,
    'LIC Plate': false,
    'Vendor': false,
    'Plnt': false,
    'Model Code': false,
    'Model Description': false,
    'Model Year': false,
    'Asset Type': false,
    'Owner': false,
    'Vehicle ID No.': false,
    'Vehicle Model': false,
  };

  /// Generates the report preview screen based on the selected fields.
  void _generateReport(List<ItemModel> allItems) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => _ReportPreviewScreen(
        items: allItems,
        // Filters selected fields based on user choices (value = true).
        selectedFields:
            _selectedFields.keys.where((key) => _selectedFields[key]!).toList(),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    // Access the local data store to get all items.
    final dataStore = Provider.of<LocalDataStore>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Report Builder'),
        backgroundColor: theme.cardColor,
        elevation: 1,
        iconTheme: IconThemeData(color: theme.textTheme.bodyLarge?.color),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instruction text
            Text(
              'Select fields to include in your report:',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            // Card container for checkboxes
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: _selectedFields.keys.map((String key) {
                    // Each field is displayed as a CheckboxListTile
                    return CheckboxListTile(
                      title: Text(key),
                      value: _selectedFields[key],
                      onChanged: (bool? value) {
                        // Update selection state when toggled
                        setState(() {
                          _selectedFields[key] = value!;
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Button to generate report with selected fields
            ElevatedButton.icon(
              onPressed: () => _generateReport(dataStore.items),
              icon: Icon(Icons.analytics_outlined),
              label: const Text('Generate Report'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Preview screen for the generated report.
/// Displays the report in a DataTable and allows download (prototype).
class _ReportPreviewScreen extends StatelessWidget {
  final List<ItemModel> items;
  final List<String> selectedFields;

  const _ReportPreviewScreen({
    required this.items,
    required this.selectedFields,
  });

  /// Placeholder for report download functionality.
  void _downloadReport(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Report download started (prototype)'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Preview'),
        backgroundColor: theme.cardColor,
        elevation: 1,
        iconTheme: IconThemeData(color: theme.textTheme.bodyLarge?.color),
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal, // Horizontal scroll for wide tables
        child: Column(
          children: [
            // DataTable to display items
            DataTable(
              columns: selectedFields
                  .map((field) => DataColumn(label: Text(field)))
                  .toList(),
              rows: items.map((item) {
                return DataRow(
                  cells: selectedFields.map((field) {
                    // Map each selected field to its corresponding item property
                    String value = 'N/A'; // Default fallback value
                    switch (field) {
                      case 'ID':
                        value = item.id;
                        break;
                      case 'Name':
                        value = item.name;
                        break;
                      case 'Category':
                        value = item.category;
                        break;
                      case 'Department':
                        value = item.department ?? 'N/A';
                        break;
                      case 'Assigned Staff':
                        value = item.assignedStaff ?? 'N/A';
                        break;
                      case 'Purchase Price':
                        value = item.purchasePrice?.toStringAsFixed(2) ?? 'N/A';
                        break;
                      case 'Purchase Date':
                        // Format date as YYYY-MM-DD
                        value = item.purchaseDate
                            .toLocal()
                            .toString()
                            .split(' ')[0];
                        break;
                      case 'Current Value':
                        value = item.currentValue?.toStringAsFixed(2) ?? 'N/A';
                        break;
                      case 'Status':
                        value = item.isPending ? 'Pending' : 'Approved';
                        break;
                      case 'CoCD':
                        value = item.coCd ?? 'N/A';
                        break;
                      case 'SAP Class':
                        value = item.sapClass ?? 'N/A';
                        break;
                      case 'Asset Class Desc':
                        value = item.assetClassDesc ?? 'N/A';
                        break;
                      case 'APC Acct':
                        value = item.apcAcct ?? 'N/A';
                        break;
                      case 'LIC Plate':
                        value = item.licPlate ?? 'N/A';
                        break;
                      case 'Vendor':
                        value = item.vendor ?? 'N/A';
                        break;
                      case 'Plnt':
                        value = item.plnt ?? 'N/A';
                        break;
                      case 'Model Code':
                        value = item.modelCode ?? 'N/A';
                        break;
                      case 'Model Description':
                        value = item.modelDesc ?? 'N/A';
                        break;
                      case 'Model Year':
                        value = item.modelYear ?? 'N/A';
                        break;
                      case 'Asset Type':
                        value = item.assetType ?? 'N/A';
                        break;
                      case 'Owner':
                        value = item.owner ?? 'N/A';
                        break;
                      case 'Vehicle ID No.':
                        value = item.vehicleIdNo ?? 'N/A';
                        break;
                      case 'Vehicle Model':
                        value = item.vehicleModel ?? 'N/A';
                        break;
                    }
                    return DataCell(Text(value));
                  }).toList(),
                );
              }).toList(),
            ),
            // Button to trigger report download
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: () => _downloadReport(context),
                icon: const Icon(Icons.download),
                label: const Text('Download Report'),
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
