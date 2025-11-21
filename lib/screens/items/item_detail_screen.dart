import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../models/firestore_models.dart';
import '../../services/firebase_services.dart';
import '../../services/qr_download_service.dart';
import '../../services/qr_generation_service.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/comments_section.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/issues_section.dart';
import '../../widgets/image_upload_widget.dart';
import '../../widgets/item_action_dialogs.dart';
import '../../widgets/transaction_history_section.dart';
import 'edit_item_screen.dart';

class ItemDetailScreen extends StatelessWidget {
  const ItemDetailScreen({super.key, required this.item});

  final InventoryItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(item.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Item',
            onPressed: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => EditItemScreen(item: item),
                ),
              );
              if (result == true && context.mounted) {
                Navigator.of(context).pop(true);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete Item',
            onPressed: () async {
              final confirmed = await ConfirmationDialog.showDelete(
                context,
                itemName: item.name,
              );
              if (confirmed && context.mounted) {
                try {
                  final catalog = context.read<CatalogService>();
                  await catalog.deleteItem(item.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Item deleted')),
                    );
                    Navigator.of(context).pop();
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error deleting item: $e')),
                    );
                  }
                }
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionCard(
            title: 'Item Image',
            child: ImageUploadWidget(
              itemId: item.id,
              currentImageUrl: item.thumbnailUrl,
              onImageUploaded: (url) {
                // Refresh the screen to show new image
                Navigator.of(context).pop(true);
              },
            ),
          ),
          _SectionCard(
            title: 'QR Code',
            child: _QrCodeSection(item: item),
          ),
          _SectionCard(
            title: 'Purchase Details',
            subtitle: 'Supplier and purchase information',
            child: _TwoColumnRows(
              rows: [
                _RowValue('Purchase Date',
                    DateFormatter.formatDate(item.purchaseDate)),
                _RowValue(
                    'Supplier',
                    _valueFrom(
                        [item.supplier, item.customFields?['supplier']])),
                _RowValue(
                    'Purchase Price',
                    _valueFrom([
                      item.purchasePrice,
                      item.customFields?['purchasePrice']
                    ])),
                _RowValue('Current Value',
                    item.customFields?['currentValue']?.toString() ?? 'N/A'),
              ],
            ),
          ),
          _SectionCard(
            title: 'SAP Details',
            subtitle: 'ERP-specific asset metadata',
            child: _TwoColumnRows(
              rows: [
                _RowValue(
                    'CoCD',
                    _valueFrom([
                      item.coCd,
                      item.customFields?['coCd'],
                      item.customFields?['cocd']
                    ])),
                _RowValue(
                    'SAP Class',
                    _valueFrom(
                        [item.sapClass, item.customFields?['sapClass']])),
                _RowValue(
                    'Asset Class Desc',
                    _valueFrom([
                      item.assetClassDesc,
                      item.customFields?['assetClass'],
                      item.customFields?['assetClassDesc']
                    ])),
                _RowValue(
                    'APC Account',
                    _valueFrom([
                      item.apcAccount,
                      item.customFields?['apcAcct'],
                      item.customFields?['apcAccount']
                    ])),
                _RowValue(
                    'License Plate',
                    _valueFrom([
                      item.licensePlate,
                      item.customFields?['licensePlate'],
                      item.customFields?['licPlate']
                    ])),
                _RowValue(
                    'Vendor',
                    _valueFrom([
                      item.vendor,
                      item.supplier,
                      item.customFields?['vendor'],
                      item.customFields?['supplier']
                    ])),
                _RowValue(
                    'Plant',
                    _valueFrom([
                      item.plant,
                      item.customFields?['plant'],
                      item.customFields?['plnt']
                    ])),
                _RowValue('Owner',
                    _valueFrom([item.owner, item.customFields?['owner']])),
                _RowValue(
                    'Vehicle ID',
                    _valueFrom([
                      item.vehicleId,
                      item.customFields?['vehicleIdNumber'],
                      item.customFields?['vehicleId']
                    ])),
              ],
            ),
          ),
          _SectionCard(
            title: 'Shelf Life',
            subtitle: 'Shelf life information and expiration',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    _valueFrom([
                      item.shelfLifeYears,
                      item.customFields?['shelfLifeYears'],
                      item.customFields?['shelfLife']
                    ]),
                    style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () =>
                      ItemActionDialogs.showEditShelfLifeDialog(context, item),
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Shelf Life'),
                ),
              ],
            ),
          ),
          _SectionCard(
            title: 'Condition',
            subtitle: 'Current condition and status',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.customFields?['condition']?.toString() ?? 'Unknown',
                    style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () =>
                      ItemActionDialogs.showEditConditionDialog(context, item),
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Condition'),
                ),
              ],
            ),
          ),
          _SectionCard(
            title: 'Warranty Information',
            subtitle: 'View and manage warranty details',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TwoColumnRows(rows: [
                  _RowValue(
                      'Warranty Provider',
                      item.customFields?['warrantyProvider']?.toString() ??
                          'N/A'),
                  _RowValue(
                      'Expires On',
                      item.customFields?['warrantyExpiry']?.toString() ??
                          'N/A'),
                ]),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () =>
                      ItemActionDialogs.showWarrantyDialog(context, item),
                  icon: const Icon(Icons.edit_calendar),
                  label: const Text('Set/Update Warranty'),
                ),
              ],
            ),
          ),
          _SectionCard(
            title: 'Technical Specifications',
            subtitle: 'Technical details and specifications',
            child: _TwoColumnRows(rows: [
              _RowValue('Item Type', item.categoryId),
              _RowValue('Model Code',
                  item.customFields?['modelCode']?.toString() ?? 'N/A'),
              _RowValue('Model Description',
                  item.customFields?['modelDesc']?.toString() ?? 'N/A'),
              _RowValue('Serial Number',
                  item.customFields?['serialNumber']?.toString() ?? 'N/A'),
            ]),
          ),
          _SectionCard(
            title: 'Maintenance',
            subtitle: 'Maintenance schedule and history',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TwoColumnRows(rows: [
                  _RowValue(
                      'Last Maintenance',
                      item.customFields?['lastMaintenance']?.toString() ??
                          'N/A'),
                  _RowValue(
                      'Next Maintenance',
                      item.customFields?['nextMaintenance']?.toString() ??
                          'N/A'),
                ]),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () =>
                      ItemActionDialogs.showMaintenanceDialog(context, item),
                  icon: const Icon(Icons.build),
                  label: const Text('Schedule Maintenance'),
                ),
              ],
            ),
          ),
          _SectionCard(
            title: 'Tags',
            subtitle: 'Item tags and labels',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TwoColumnRows(rows: [
                  _RowValue('Asset Number', item.assetId),
                  _RowValue('Tagged', item.qrCodeUrl != null ? 'Yes' : 'No'),
                  _RowValue('Written Off',
                      item.customFields?['writtenOff']?.toString() ?? 'No'),
                  _RowValue('QR Code ID', item.assetId),
                ]),
              ],
            ),
          ),
          _SectionCard(
            title: 'Reminders',
            subtitle: 'Scheduled reminders for this item',
            child: _RemindersSection(item: item),
          ),
          _SectionCard(
            title: 'Issues',
            subtitle: 'Reported problems for this item',
            child: IssuesSection(itemId: item.id),
          ),
          _SectionCard(
            title: 'Comments',
            subtitle: 'View and add comments for this item',
            child: CommentsSection(itemId: item.id),
          ),
          _SectionCard(
            title: 'Transaction History',
            subtitle: 'View check-in/checkout events and signatures',
            child: TransactionHistorySection(itemId: item.id),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, this.subtitle, required this.child});

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
            ],
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _TwoColumnRows extends StatelessWidget {
  const _TwoColumnRows({required this.rows});

  final List<_RowValue> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: rows
          .map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      row.label,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.grey[600]),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      row.value,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

String _valueFrom(List<dynamic> values) {
  for (final value in values) {
    if (value == null) continue;
    if (value is String) {
      if (value.trim().isEmpty) continue;
      return value;
    }
    if (value is num) {
      return value.toString();
    }
    final text = value.toString();
    if (text.isNotEmpty) return text;
  }
  return 'N/A';
}

class _RowValue {
  const _RowValue(this.label, this.value);

  final String label;
  final String value;
}

class _QrCodeSection extends StatefulWidget {
  const _QrCodeSection({required this.item});

  final InventoryItem item;

  @override
  State<_QrCodeSection> createState() => _QrCodeSectionState();
}

class _QrCodeSectionState extends State<_QrCodeSection> {
  bool _isGenerating = false;

  Future<void> _generateQrCode() async {
    setState(() => _isGenerating = true);
    try {
      final catalog = context.read<CatalogService>();

      // Generate QR code and upload to Firebase Storage
      final qrCodeUrl =
          await QrGenerationService.generateAndUploadQrCode(widget.item);

      // Update item with QR code URL
      await catalog.updateItem(widget.item.id, {
        'qrCodeUrl': qrCodeUrl,
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('QR Code generated successfully')),
        );
        Navigator.of(context).pop(true); // Refresh item detail
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating QR code: $e')),
        );
      }
    } finally {
      if (context.mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  Future<void> _downloadQrCode() async {
    try {
      final qrData = QrGenerationService.generateQrCodeData(widget.item);
      await QrDownloadService.downloadQrCode(qrData, widget.item.assetId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('QR Code shared successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error downloading QR code: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasQrCode =
        widget.item.qrCodeUrl != null && widget.item.qrCodeUrl!.isNotEmpty;

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[300]!),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (hasQrCode)
                QrImageView(
                  data: QrGenerationService.generateQrCodeData(widget.item),
                  version: QrVersions.auto,
                  size: 200,
                  backgroundColor: Colors.white,
                )
              else
                const Icon(Icons.qr_code_2, size: 120, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                widget.item.assetId,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  if (!hasQrCode)
                    FilledButton.icon(
                      onPressed: _isGenerating ? null : _generateQrCode,
                      icon: _isGenerating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.qr_code),
                      label: const Text('Generate QR'),
                    ),
                  if (hasQrCode)
                    OutlinedButton.icon(
                      onPressed: _downloadQrCode,
                      icon: const Icon(Icons.download),
                      label: const Text('Download QR Code'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RemindersSection extends StatelessWidget {
  const _RemindersSection({required this.item});

  final InventoryItem item;

  @override
  Widget build(BuildContext context) {
    final reminders = (item.customFields?['reminders'] as List?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (reminders.isEmpty)
          Text('No reminders for this item.',
              style: Theme.of(context).textTheme.bodyMedium)
        else
          ...reminders.map((reminder) {
            final reminderData = reminder as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.notifications_outlined),
                title: Text(reminderData['title']?.toString() ?? 'Reminder'),
                subtitle: Text(reminderData['notes']?.toString() ?? ''),
                trailing: Text(
                  reminderData['date'] != null
                      ? DateTime.tryParse(reminderData['date'])
                              ?.toString()
                              .substring(0, 10) ??
                          ''
                      : '',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            );
          }),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () =>
              ItemActionDialogs.showAddReminderDialog(context, item),
          icon: const Icon(Icons.add_alert_outlined),
          label: const Text('Add Reminder'),
        ),
      ],
    );
  }
}
