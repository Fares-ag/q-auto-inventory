// lib/widgets/traceability_report_screen.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/history_entry_model.dart';
import 'package:flutter_application_1/models/item_model.dart';
import 'package:flutter_application_1/services/local_data_store.dart';
import 'package:flutter_application_1/services/pdf_generator.dart';
import 'package:provider/provider.dart';

class TraceabilityReportScreen extends StatefulWidget {
  const TraceabilityReportScreen({super.key});

  @override
  State<TraceabilityReportScreen> createState() =>
      _TraceabilityReportScreenState();
}

class _TraceabilityReportScreenState extends State<TraceabilityReportScreen> {
  ItemModel? _selectedItem;

  void _showFullSignatureImage(Uint8List signatureBytes) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Image.memory(signatureBytes),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dataStore = Provider.of<LocalDataStore>(context);
    final allItems = dataStore.items;
    final allHistory = dataStore.history;

    final List<HistoryEntry> itemHistory = _selectedItem == null
        ? []
        : allHistory.where((h) => h.targetId == _selectedItem!.id).toList();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Traceability Report'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          if (_selectedItem != null)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_outlined),
              onPressed: () => PdfGenerator.generateTraceabilityReport(
                  _selectedItem!, itemHistory),
              tooltip: 'Download as PDF',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Item Selection Card ---
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select an Item to Trace',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<ItemModel>(
                      value: _selectedItem,
                      decoration: InputDecoration(
                          labelText: 'Item',
                          border: const OutlineInputBorder(),
                          fillColor: Colors.grey[50],
                          filled: true),
                      items: allItems.map((ItemModel item) {
                        return DropdownMenuItem<ItemModel>(
                          value: item,
                          child: Text('${item.name} (${item.id})'),
                        );
                      }).toList(),
                      onChanged: (ItemModel? newValue) {
                        setState(() {
                          _selectedItem = newValue;
                        });
                      },
                      isExpanded: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- History Display Section ---
            if (_selectedItem != null)
              _buildSectionTitle(theme, 'History for ${_selectedItem!.name}'),
            const SizedBox(height: 16),
            if (_selectedItem != null)
              itemHistory.isEmpty
                  ? _buildEmptyStateCard('No history found for this item.')
                  : Column(
                      children: itemHistory
                          .map((entry) => _buildHistoryCard(entry))
                          .toList(),
                    ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Text(title,
        style: theme.textTheme.titleLarge
            ?.copyWith(fontWeight: FontWeight.bold, color: Colors.black87));
  }

  Widget _buildEmptyStateCard(String message) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40.0),
          child: Text(message, style: TextStyle(color: Colors.grey[600])),
        ),
      ),
    );
  }

  Widget _buildHistoryCard(HistoryEntry entry) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.black.withOpacity(0.05),
                child: Icon(entry.icon ?? Icons.history, color: Colors.black),
              ),
              title: Text(entry.title,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('By: ${entry.actorEmail}\n${entry.description}'),
              trailing: Text(
                "${entry.timestamp.toLocal().toString().split(' ')[0]}\n${entry.timestamp.hour}:${entry.timestamp.minute.toString().padLeft(2, '0')}",
                textAlign: TextAlign.right,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              isThreeLine: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            if (entry.assigneeSignature != null ||
                entry.operatorSignature != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (entry.assigneeSignature != null)
                      _buildSignatureThumbnail(
                          'Assignee', entry.assigneeSignature!),
                    if (entry.operatorSignature != null)
                      _buildSignatureThumbnail(
                          'Operator', entry.operatorSignature!),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignatureThumbnail(String label, Uint8List signatureBytes) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 4),
        InkWell(
          onTap: () => _showFullSignatureImage(signatureBytes),
          child: Container(
            width: 120,
            height: 60,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Image.memory(signatureBytes, fit: BoxFit.contain),
          ),
        ),
      ],
    );
  }
}
