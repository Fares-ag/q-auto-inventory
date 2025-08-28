// lib/widgets/bulk_assign_screen.dart

import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/item_model.dart';
import 'package:flutter_application_1/services/local_data_store.dart';
import 'package:flutter_signature_pad/flutter_signature_pad.dart';
import 'package:provider/provider.dart';

class BulkAssignScreen extends StatefulWidget {
  const BulkAssignScreen({Key? key}) : super(key: key);

  @override
  State<BulkAssignScreen> createState() => _BulkAssignScreenState();
}

class _BulkAssignScreenState extends State<BulkAssignScreen> {
  // State variables to manage the process
  final Set<ItemModel> _selectedItems = {};
  final _assignToController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final GlobalKey<SignatureState> _assigneeSignatureKey =
      GlobalKey<SignatureState>();
  final GlobalKey<SignatureState> _operatorSignatureKey =
      GlobalKey<SignatureState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _assignToController.dispose();
    super.dispose();
  }

  /// Toggles the selection of an item
  void _toggleItemSelection(ItemModel item) {
    setState(() {
      if (_selectedItems.contains(item)) {
        _selectedItems.remove(item);
      } else {
        _selectedItems.add(item);
      }
    });
  }

  /// Proceeds to the final signature and confirmation step
  void _proceedToSignature(BuildContext context) {
    if (_selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one item.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _buildSignatureSheet(context),
    );
  }

  /// Handles the final save operation
  void _saveBulkAssignment(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    final assigneeSignaturePad = _assigneeSignatureKey.currentState;
    final operatorSignaturePad = _operatorSignatureKey.currentState;

    if (assigneeSignaturePad == null ||
        assigneeSignaturePad.points.isEmpty ||
        operatorSignaturePad == null ||
        operatorSignaturePad.points.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Both signatures are required.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // In a real app, you would upload signatures here. We simulate it.
    await Future.delayed(const Duration(milliseconds: 500));

    final dataStore = Provider.of<LocalDataStore>(context, listen: false);
    final itemIds = _selectedItems.map((item) => item.id).toList();
    final assignTo = _assignToController.text.trim();

    dataStore.bulkCheckoutItems(itemIds, assignTo);

    setState(() => _isLoading = false);

    // Pop twice to close the modal and the main screen
    Navigator.of(context).pop();
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${itemIds.length} items assigned to $assignTo.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataStore = Provider.of<LocalDataStore>(context);
    // We only want to show items that are currently available to be checked out
    final availableItems =
        dataStore.items.where((item) => item.isAvailable).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bulk Assign Items'),
      ),
      body: Column(
        children: [
          Expanded(
            child: availableItems.isEmpty
                ? const Center(child: Text('No available items to assign.'))
                : ListView.builder(
                    itemCount: availableItems.length,
                    itemBuilder: (context, index) {
                      final item = availableItems[index];
                      final isSelected = _selectedItems.contains(item);
                      return CheckboxListTile(
                        title: Text(item.name),
                        subtitle:
                            Text('ID: ${item.id} | Category: ${item.category}'),
                        value: isSelected,
                        onChanged: (bool? value) {
                          _toggleItemSelection(item);
                        },
                        activeColor: Colors.black,
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => _proceedToSignature(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                ),
                child:
                    Text('Proceed (${_selectedItems.length} items selected)'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the bottom sheet for summary and signatures
  Widget _buildSignatureSheet(BuildContext context) {
    return StatefulBuilder(builder: (context, setModalState) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Confirm Assignment',
                    style:
                        TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _assignToController,
                  decoration: const InputDecoration(
                      labelText: 'Assign To Staff Member'),
                  validator: (val) =>
                      val!.isEmpty ? 'Please enter a name' : null,
                ),
                const SizedBox(height: 16),
                const Text('Items to be assigned:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                ..._selectedItems.map((item) => Text('- ${item.name}')),
                const SizedBox(height: 20),
                const Text('Assignee Signature',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                _buildSignaturePad(_assigneeSignatureKey),
                const SizedBox(height: 20),
                const Text('Operator Signature',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                _buildSignaturePad(_operatorSignatureKey),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed:
                        _isLoading ? null : () => _saveBulkAssignment(context),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Confirm Assignment'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildSignaturePad(GlobalKey<SignatureState> key) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Signature(key: key, strokeWidth: 3.0),
    );
  }
}
