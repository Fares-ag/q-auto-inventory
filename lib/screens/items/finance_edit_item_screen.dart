import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';

import '../../models/firestore_models.dart';
import '../../services/firebase_services.dart';
import '../../services/image_upload_service.dart';
import '../../widgets/signature_pad.dart';

/// Finance-specific edit screen that only allows editing:
/// - Asset Number
/// - Purchase Price
/// - Current Value
/// - SAP Codes (CoCD, SAP Class, APC Account, Asset Class Description)
/// - Any other cost-related fields
/// 
/// Note: Finance users can VIEW all asset information in the detail screen,
/// but can only EDIT the fields listed above.
class FinanceEditItemScreen extends StatefulWidget {
  const FinanceEditItemScreen({super.key, required this.item});

  final InventoryItem item;

  @override
  State<FinanceEditItemScreen> createState() => _FinanceEditItemScreenState();
}

class _FinanceEditItemScreenState extends State<FinanceEditItemScreen> {
  late final _formKey = GlobalKey<FormState>();
  late final _assetNumberController =
      TextEditingController(text: widget.item.assetNumber ?? '');
  late final _purchasePriceController = TextEditingController(
      text: widget.item.purchasePrice?.toString() ?? '');
  late final _currentValueController = TextEditingController(
      text: widget.item.customFields?['currentValue']?.toString() ?? '');
  late final _cocdController =
      TextEditingController(text: widget.item.coCd ?? '');
  late final _sapClassController =
      TextEditingController(text: widget.item.sapClass ?? '');
  late final _apcAccountController =
      TextEditingController(text: widget.item.apcAccount ?? '');
  late final _assetClassDescController =
      TextEditingController(text: widget.item.assetClassDesc ?? '');

  bool _isLoading = false;

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;

    // Require signature before saving
    final signatureBytes = await _captureSignature();
    if (signatureBytes == null) {
      // User cancelled signature - don't save
      return;
    }

    setState(() => _isLoading = true);

    try {
      final catalog = context.read<CatalogService>();
      final purchasePriceText = _purchasePriceController.text.trim();
      final currentValueText = _currentValueController.text.trim();

      final updates = <String, dynamic>{};

      // Asset Number
      if (_assetNumberController.text.trim().isNotEmpty) {
        updates['assetNumber'] = _assetNumberController.text.trim();
      } else {
        updates['assetNumber'] = null; // Allow clearing
      }

      // Purchase Price
      if (purchasePriceText.isNotEmpty) {
        final price = double.tryParse(purchasePriceText);
        if (price != null) {
          updates['purchasePrice'] = price;
        }
      } else {
        updates['purchasePrice'] = null; // Allow clearing
      }

      // Current Value (stored in customFields)
      final customFields = Map<String, dynamic>.from(
          widget.item.customFields ?? {});
      if (currentValueText.isNotEmpty) {
        final value = double.tryParse(currentValueText);
        if (value != null) {
          customFields['currentValue'] = value;
        } else {
          customFields.remove('currentValue');
        }
      } else {
        customFields.remove('currentValue');
      }
      updates['customFields'] = customFields;

      // SAP Codes
      if (_cocdController.text.trim().isNotEmpty) {
        updates['coCd'] = _cocdController.text.trim();
      } else {
        updates['coCd'] = null; // Allow clearing
      }

      if (_sapClassController.text.trim().isNotEmpty) {
        updates['sapClass'] = _sapClassController.text.trim();
      } else {
        updates['sapClass'] = null; // Allow clearing
      }

      if (_apcAccountController.text.trim().isNotEmpty) {
        updates['apcAcct'] = _apcAccountController.text.trim();
      } else {
        updates['apcAcct'] = null; // Allow clearing
      }

      if (_assetClassDescController.text.trim().isNotEmpty) {
        updates['assetClassDesc'] = _assetClassDescController.text.trim();
      } else {
        updates['assetClassDesc'] = null; // Allow clearing
      }

      // Upload signature first
      String? signatureUrl;
      try {
        final uploadService = ImageUploadService();
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/signature_${DateTime.now().millisecondsSinceEpoch}.png');
        await file.writeAsBytes(signatureBytes);
        final signaturePath = 'signatures/${widget.item.id}/finance_edit_${DateTime.now().millisecondsSinceEpoch}.png';
        signatureUrl = await uploadService.uploadFile(signaturePath, file);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error uploading signature: $e')),
          );
        }
        return;
      }

      await catalog.updateItem(widget.item.id, updates);

      // Record finance edit history with updated fields and signature
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final historyService = context.read<HistoryService>();
        await historyService.recordFinanceEdit(
          widget.item.id,
          user.uid,
          updates: updates,
          signatureUrl: signatureUrl,
        );
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Financial information updated successfully')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating item: $e')),
        );
      }
    } finally {
      if (context.mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<Uint8List?> _captureSignature() async {
    return await Navigator.of(context).push<Uint8List>(
      MaterialPageRoute(
        builder: (_) => SignaturePad(
          title: 'Finance Edit Signature',
          onSignatureSaved: (sig) {
            Navigator.of(context).pop(sig);
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _assetNumberController.dispose();
    _purchasePriceController.dispose();
    _currentValueController.dispose();
    _cocdController.dispose();
    _sapClassController.dispose();
    _apcAccountController.dispose();
    _assetClassDescController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Financial Info - ${widget.item.name}'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveItem,
              tooltip: 'Save Changes',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Finance Role: You can view all asset information, but can only edit asset number, financial fields, and SAP codes.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Asset Number
            TextFormField(
              controller: _assetNumberController,
              decoration: const InputDecoration(
                labelText: 'Asset Number',
                hintText: 'Optional asset number',
                border: OutlineInputBorder(),
                helperText: 'Additional asset identifier',
                prefixIcon: Icon(Icons.numbers),
              ),
            ),
            const SizedBox(height: 24),

            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Financial Information',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Purchase Price
            TextFormField(
              controller: _purchasePriceController,
              decoration: const InputDecoration(
                labelText: 'Purchase Price',
                hintText: '0.00',
                prefixText: '\$ ',
                border: OutlineInputBorder(),
                helperText: 'Original purchase price',
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value != null && value.trim().isNotEmpty) {
                  final price = double.tryParse(value);
                  if (price == null) {
                    return 'Please enter a valid number';
                  }
                  if (price < 0) {
                    return 'Price cannot be negative';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Current Value
            TextFormField(
              controller: _currentValueController,
              decoration: const InputDecoration(
                labelText: 'Current Value',
                hintText: '0.00',
                prefixText: '\$ ',
                border: OutlineInputBorder(),
                helperText: 'Current market/depreciated value',
                prefixIcon: Icon(Icons.account_balance_wallet),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value != null && value.trim().isNotEmpty) {
                  final val = double.tryParse(value);
                  if (val == null) {
                    return 'Please enter a valid number';
                  }
                  if (val < 0) {
                    return 'Value cannot be negative';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 32),

            const Divider(),
            const SizedBox(height: 16),
            Text(
              'SAP Codes',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // CoCD
            TextFormField(
              controller: _cocdController,
              decoration: const InputDecoration(
                labelText: 'CoCD (Company Code)',
                hintText: 'e.g., 8000, 8500',
                border: OutlineInputBorder(),
                helperText: 'SAP Company Code',
                prefixIcon: Icon(Icons.business),
              ),
            ),
            const SizedBox(height: 16),

            // SAP Class
            TextFormField(
              controller: _sapClassController,
              decoration: const InputDecoration(
                labelText: 'SAP Class',
                hintText: 'e.g., 2600, 3000, 3400',
                border: OutlineInputBorder(),
                helperText: 'SAP Asset Class',
                prefixIcon: Icon(Icons.category),
              ),
            ),
            const SizedBox(height: 16),

            // APC Account
            TextFormField(
              controller: _apcAccountController,
              decoration: const InputDecoration(
                labelText: 'APC Account',
                hintText: 'e.g., 110170, 110210',
                border: OutlineInputBorder(),
                helperText: 'APC Account Code',
                prefixIcon: Icon(Icons.account_balance),
              ),
            ),
            const SizedBox(height: 16),

            // Asset Class Description
            TextFormField(
              controller: _assetClassDescController,
              decoration: const InputDecoration(
                labelText: 'Asset Class Description',
                hintText: 'e.g., Office Equipment, IT Hardware',
                border: OutlineInputBorder(),
                helperText: 'Description of the asset class',
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 32),

            // Save Button
            FilledButton.icon(
              onPressed: _isLoading ? null : _saveItem,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(_isLoading ? 'Saving...' : 'Save Financial Information'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

