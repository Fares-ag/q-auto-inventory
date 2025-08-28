// lib/widgets/custom_report_builder_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/item_model.dart';
import 'package:flutter_application_1/services/local_data_store.dart';
import 'package:flutter_application_1/widgets/report_preview_screen.dart';
import 'package:provider/provider.dart';

class CustomReportBuilderScreen extends StatefulWidget {
  const CustomReportBuilderScreen({super.key});

  @override
  State<CustomReportBuilderScreen> createState() =>
      _CustomReportBuilderScreenState();
}

class _CustomReportBuilderScreenState extends State<CustomReportBuilderScreen> {
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

  void _generateReport(BuildContext context, List<ItemModel> allItems) {
    final selectedHeaders =
        _selectedFields.keys.where((key) => _selectedFields[key]!).toList();

    if (selectedHeaders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one field.')));
      return;
    }

    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => ReportPreviewScreen(
        items: allItems,
        selectedFields: selectedHeaders,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final dataStore = Provider.of<LocalDataStore>(context, listen: false);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Report Builder'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Select fields to include in your report:',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: _selectedFields.keys.map((String key) {
                    return CheckboxListTile(
                      title: Text(key),
                      value: _selectedFields[key],
                      onChanged: (bool? value) {
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
            ElevatedButton.icon(
              onPressed: () => _generateReport(context, dataStore.items),
              icon: const Icon(Icons.analytics_outlined),
              label: const Text('Generate Preview'),
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
