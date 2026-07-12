import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../models/firestore_models.dart';
import '../../providers/permission_providers.dart';
import '../../services/firebase_services.dart';
import '../../services/qr_download_service.dart';
import '../../services/qr_generation_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_spacing.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/comments_section.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/issues_section.dart';
import '../../widgets/image_upload_widget.dart';
import '../../widgets/item_action_dialogs.dart';
import '../../widgets/transaction_history_section.dart';
import '../../services/permission_service.dart';
import '../../services/offline_queue_service.dart';
import '../../utils/network_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'edit_item_screen.dart';
import 'finance_edit_item_screen.dart';

class ItemDetailScreen extends ConsumerStatefulWidget {
  const ItemDetailScreen({super.key, required this.item});

  final InventoryItem item;

  @override
  ConsumerState<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends ConsumerState<ItemDetailScreen> {
  late InventoryItem _item;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
  }

  Future<void> _reloadItemFromServer() async {
    try {
      final catalog = context.read<CatalogService>();
      final fresh = await catalog.getItem(_item.id);
      if (fresh != null && mounted) {
        setState(() => _item = fresh);
      }
    } catch (_) {}
  }

  Future<void> _handleEdit(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final permissionService = context.read<PermissionService>();
    final isFinance = await permissionService.isFinance(user.uid);
    final isAdmin = await permissionService.isAdmin(user.uid);

    if (isFinance && !isAdmin) {
      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => FinanceEditItemScreen(item: _item),
        ),
      );
      if (result == true && context.mounted) {
        Navigator.of(context).pop(true);
      }
    } else {
      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => EditItemScreen(item: _item),
        ),
      );
      if (result == true && context.mounted) {
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Single Riverpod call replaces 3 separate FutureBuilders.
    // The result is cached for the session — no re-fire on rebuild.
    final permsAsync = ref.watch(itemPermissionsProvider(_item.id));

    final canEdit = permsAsync.valueOrNull?.canEdit ?? false;
    final canDelete = permsAsync.valueOrNull?.canDelete ?? false;
    final canEditFinancial = permsAsync.valueOrNull?.canEditFinancial ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(_item.name),
        actions: [
          if (permsAsync.isLoading)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else ...[
            if (canEdit)
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit Item',
                onPressed: () => _handleEdit(context),
              ),
            if (canDelete)
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Delete Item',
                onPressed: () async {
                  final confirmed = await ConfirmationDialog.showDelete(
                    context,
                    itemName: _item.name,
                  );
                  if (confirmed && context.mounted) {
                    try {
                      final catalog = context.read<CatalogService>();
                      final queue = context.read<OfflineQueueService>();
                      final online = await NetworkUtils.hasInternetConnection();
                      await catalog.deleteItem(_item.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              online || queue.queuedCount == 0
                                  ? 'Item deleted'
                                  : 'Offline: delete queued to sync',
                            ),
                          ),
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
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xl3,
        ),
        children: [
          _SectionCard(
            title: 'Item Image',
            child: ImageUploadWidget(
              itemId: _item.id,
              currentImageUrl: _item.thumbnailUrl,
              onImageUploaded: (url) {
                // Refresh the screen to show new image
                Navigator.of(context).pop(true);
              },
            ),
          ),
          _SectionCard(
            title: 'QR Code',
            child: _QrCodeSection(qrItem: _item),
          ),
          _SectionCard(
            title: 'Purchase Details',
            subtitle: 'Supplier and purchase information',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TwoColumnRows(
                  rows: [
                    _RowValue('Purchase Date',
                        DateFormatter.formatDate(_item.purchaseDate)),
                    _RowValue(
                        'Supplier',
                        _valueFrom(
                            [_item.supplier, _item.customFields?['supplier']])),
                    _RowValue(
                        'Purchase Price',
                        _valueFrom([
                          _item.purchasePrice,
                          _item.customFields?['purchasePrice']
                        ])),
                    _RowValue('Current Value',
                        _item.customFields?['currentValue']?.toString() ?? 'N/A'),
                  ],
                ),
                const SizedBox(height: 12),
                if (canEditFinancial)
                  FilledButton.icon(
                    onPressed: () => _handleEdit(context),
                    icon: const Icon(Icons.edit_rounded),
                    label: const Text('Edit Financial Information'),
                  ),
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
                      _item.coCd,
                      _item.customFields?['coCd'],
                      _item.customFields?['cocd']
                    ])),
                _RowValue(
                    'SAP Class',
                    _valueFrom(
                        [_item.sapClass, _item.customFields?['sapClass']])),
                _RowValue(
                    'Asset Class Desc',
                    _valueFrom([
                      _item.assetClassDesc,
                      _item.customFields?['assetClass'],
                      _item.customFields?['assetClassDesc']
                    ])),
                _RowValue(
                    'APC Account',
                    _valueFrom([
                      _item.apcAccount,
                      _item.customFields?['apcAcct'],
                      _item.customFields?['apcAccount']
                    ])),
                _RowValue(
                    'License Plate',
                    _valueFrom([
                      _item.licensePlate,
                      _item.customFields?['licensePlate'],
                      _item.customFields?['licPlate']
                    ])),
                _RowValue(
                    'Vendor',
                    _valueFrom([
                      _item.vendor,
                      _item.supplier,
                      _item.customFields?['vendor'],
                      _item.customFields?['supplier']
                    ])),
                _RowValue(
                    'Plant',
                    _valueFrom([
                      _item.plant,
                      _item.customFields?['plant'],
                      _item.customFields?['plnt']
                    ])),
                _RowValue('Owner',
                    _valueFrom([_item.owner, _item.customFields?['owner']])),
                _RowValue(
                    'Vehicle ID',
                    _valueFrom([
                      _item.vehicleId,
                      _item.customFields?['vehicleIdNumber'],
                      _item.customFields?['vehicleId']
                    ])),
              ],
            ),
          ),
          _SectionCard(
            title: 'SAP Finance Code',
            subtitle: 'SAP-specific finance/ledger code for this asset',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _valueFrom([_item.customFields?['sapFinanceCode']]),
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () async {
                    final saved =
                        await ItemActionDialogs.showEditSapFinanceCodeDialog(
                            context, _item);
                    if (!mounted) return;
                    if (saved) await _reloadItemFromServer();
                  },
                  icon: const Icon(Icons.edit_rounded),
                  label: const Text('Edit SAP Finance Code'),
                ),
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
                      _item.shelfLifeYears,
                      _item.customFields?['shelfLifeYears'],
                      _item.customFields?['shelfLife']
                    ]),
                    style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () =>
                      ItemActionDialogs.showEditShelfLifeDialog(context, _item),
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Shelf Life'),
                ),
              ],
            ),
          ),
          _SectionCard(
            title: 'Condition & Status',
            subtitle: 'Current condition and status flags',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TwoColumnRows(rows: [
                  _RowValue('Condition', _valueFrom([_item.customFields?['condition']])),
                  _RowValue('Tagged', _item.isTagged != null ? (_item.isTagged! ? 'Yes' : 'No') : (_item.qrCodeUrl != null ? 'Yes' : 'No')),
                  _RowValue('Written Off', _item.isWrittenOff != null ? (_item.isWrittenOff! ? 'Yes' : 'No') : _valueFrom([_item.customFields?['isWrittenOff'], _item.customFields?['writtenOff']])),
                ]),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () =>
                      ItemActionDialogs.showEditConditionDialog(context, _item),
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
                      'Warranty',
                      _valueFrom([_item.warranty, _item.customFields?['warranty']])),
                  _RowValue(
                      'Warranty Provider',
                      _item.customFields?['warrantyProvider']?.toString() ??
                          'N/A'),
                  _RowValue(
                      'Expires On',
                      _valueFrom([
                        _item.warrantyExpiry != null ? DateFormatter.formatDate(_item.warrantyExpiry) : null,
                        _item.customFields?['warrantyExpiry'],
                      ])),
                ]),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () =>
                      ItemActionDialogs.showWarrantyDialog(context, _item),
                  icon: const Icon(Icons.edit_calendar),
                  label: const Text('Set/Update Warranty'),
                ),
              ],
            ),
          ),
          _SectionCard(
            title: 'Basic Information',
            subtitle: 'Item identification and classification',
            child: _TwoColumnRows(rows: [
              _RowValue('Asset ID', _item.assetId),
              _RowValue('Asset Number', _valueFrom([_item.assetNumber])),
              _RowValue('Category', _item.categoryId),
              _RowValue('Item Type', _valueFrom([_item.itemType, _item.customFields?['itemType']])),
              _RowValue('Asset Type', _valueFrom([_item.assetType, _item.customFields?['assetType']])),
              _RowValue('Status', _item.status ?? 'N/A'),
              _RowValue('Available', _item.isAvailable != null ? (_item.isAvailable! ? 'Yes' : 'No') : 'N/A'),
              _RowValue('Company', _valueFrom([_item.company, _item.customFields?['company']])),
            ]),
          ),
          _SectionCard(
            title: 'Department & Location',
            subtitle: 'Organizational assignment',
            child: _TwoColumnRows(rows: [
              _RowValue('Department', _item.departmentId),
              _RowValue('Sub Department', _valueFrom([_item.subDepartment, _item.customFields?['subDepartment']])),
              _RowValue('Location', _valueFrom([_item.locationId, _item.customFields?['location']])),
              _RowValue('Assigned To', _valueFrom([_item.assignedTo, _item.customFields?['assignedStaff']])),
              _RowValue('Owner', _valueFrom([_item.owner, _item.customFields?['owner']])),
            ]),
          ),
          _SectionCard(
            title: 'Technical Specifications',
            subtitle: 'Technical details and specifications',
            child: _TwoColumnRows(rows: [
              _RowValue('Model Code', _valueFrom([_item.modelCode, _item.customFields?['modelCode']])),
              _RowValue('Model Description', _valueFrom([_item.modelDesc, _item.customFields?['modelDesc']])),
              _RowValue('Model Year', _valueFrom([_item.modelYear, _item.customFields?['modelYear']])),
              _RowValue('Serial Number', _valueFrom([_item.serialNumber, _item.customFields?['serialNumber']])),
              _RowValue('Variants', _valueFrom([_item.variants, _item.customFields?['variants']])),
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
                      _valueFrom([
                        _item.lastMaintenanceDate != null ? DateFormatter.formatDate(_item.lastMaintenanceDate) : null,
                        _item.lastServicedAt != null ? DateFormatter.formatDate(_item.lastServicedAt) : null,
                        _item.customFields?['lastMaintenanceDate'],
                        _item.customFields?['lastMaintenance'],
                      ])),
                  _RowValue(
                      'Next Maintenance',
                      _valueFrom([
                        _item.nextMaintenanceDate != null ? DateFormatter.formatDate(_item.nextMaintenanceDate) : null,
                        _item.customFields?['nextMaintenanceDate'],
                        _item.customFields?['nextMaintenance'],
                      ])),
                  _RowValue(
                      'Maintenance Schedule',
                      _valueFrom([_item.maintenanceSchedule, _item.customFields?['maintenanceSchedule']])),
                ]),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () =>
                      ItemActionDialogs.showMaintenanceDialog(context, _item),
                  icon: const Icon(Icons.build),
                  label: const Text('Schedule Maintenance'),
                ),
              ],
            ),
          ),
          _SectionCard(
            title: 'Vehicle Information',
            subtitle: 'Vehicle-specific details (if applicable)',
            child: _TwoColumnRows(rows: [
              _RowValue('License Plate', _valueFrom([_item.licensePlate, _item.customFields?['licPlate'], _item.customFields?['licensePlate']])),
              _RowValue('Vehicle ID', _valueFrom([_item.vehicleId, _item.customFields?['vehicleIdNumber'], _item.customFields?['vehicleIdNo'], _item.customFields?['vehicleId']])),
              _RowValue('Registration Date', _item.registrationDate != null ? DateFormatter.formatDate(_item.registrationDate) : 'N/A'),
              _RowValue('Mileage', _item.mileage != null ? '${_item.mileage} km' : 'N/A'),
            ]),
          ),
          _SectionCard(
            title: 'Reminders',
            subtitle: 'Scheduled reminders for this item',
            child: _RemindersSection(invItem: _item),
          ),
          _SectionCard(
            title: 'Issues',
            subtitle: 'Reported problems for this item',
            child: IssuesSection(itemId: _item.id),
          ),
          _SectionCard(
            title: 'Comments',
            subtitle: 'View and add comments for this item',
            child: CommentsSection(itemId: _item.id),
          ),
          _SectionCard(
            title: 'Transaction History',
            subtitle: 'View check-in/checkout events and signatures',
            child: TransactionHistorySection(itemId: _item.id),
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
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppSpacing.roundedLg,
        border: Border.all(color: AppTheme.lightBorder, width: 1),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      )),
            ],
            const SizedBox(height: AppSpacing.lg),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      row.label,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant),
                    ),
                  ),
                  AppSpacing.hGapMd,
                  Expanded(
                    flex: 3,
                    child: Text(
                      row.value,
                      maxLines: 6,
                      overflow: TextOverflow.ellipsis,
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
  const _QrCodeSection({required this.qrItem});

  final InventoryItem qrItem;

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
          await QrGenerationService.generateAndUploadQrCode(widget.qrItem);

      // Update item with QR code URL
      await catalog.updateItem(widget.qrItem.id, {
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
      final qrData = QrGenerationService.generateQrCodeData(widget.qrItem);
      await QrDownloadService.downloadQrCode(qrData, widget.qrItem.assetId);
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
        widget.qrItem.qrCodeUrl != null && widget.qrItem.qrCodeUrl!.isNotEmpty;

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).colorScheme.outline),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (hasQrCode)
                QrImageView(
                  data: QrGenerationService.generateQrCodeData(widget.qrItem),
                  version: QrVersions.auto,
                  size: 200,
                  backgroundColor: Colors.white,
                )
              else
                Icon(Icons.qr_code_2, size: 120, color: Theme.of(context).colorScheme.outlineVariant),
              const SizedBox(height: 16),
              Text(
                widget.qrItem.assetId,
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
  const _RemindersSection({required this.invItem});

  final InventoryItem invItem;

  @override
  Widget build(BuildContext context) {
    final reminders = (invItem.customFields?['reminders'] as List?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (reminders.isEmpty)
          Text('No reminders for this _item.',
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
              ItemActionDialogs.showAddReminderDialog(context, invItem),
          icon: const Icon(Icons.add_alert_outlined),
          label: const Text('Add Reminder'),
        ),
      ],
    );
  }
}
