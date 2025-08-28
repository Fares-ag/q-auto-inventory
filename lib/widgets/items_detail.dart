// lib/widgets/items_detail.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/history_entry_model.dart';
import 'package:flutter_application_1/models/item_model.dart';
import 'package:flutter_application_1/models/warranty_model.dart';
import 'package:flutter_application_1/widgets/checkout.dart';
import 'package:flutter_application_1/widgets/raise_issue.dart';
import 'package:flutter_application_1/widgets/checkin_widget.dart';
import 'package:flutter_application_1/models/issue_model.dart';
import 'package:flutter_application_1/models/reminder_model.dart';
import 'package:flutter_application_1/services/local_data_store.dart';
import 'package:flutter_application_1/widgets/issue_details_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:io';
import 'package:flutter_application_1/models/maintenance_log.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:flutter_application_1/services/qr_code_service.dart';
import 'edit_item_widget.dart';
import 'package:provider/provider.dart';

class QRScannerPage extends StatefulWidget {
  final Function(String) onScan;
  const QRScannerPage({super.key, required this.onScan});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR Code')),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              final barcodes = capture.barcodes;
              if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                widget.onScan(barcodes.first.rawValue!);
                Navigator.of(context).pop();
              }
            },
          ),
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green, width: 4),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ItemDetailsScreen extends StatefulWidget {
  final ItemModel item;
  final Function(ItemModel) onUpdateItem;

  const ItemDetailsScreen({
    Key? key,
    required this.item,
    required this.onUpdateItem,
  }) : super(key: key);

  @override
  State<ItemDetailsScreen> createState() => _ItemDetailsScreenState();
}

class _ItemDetailsScreenState extends State<ItemDetailsScreen> {
  bool detailsExpanded = true;
  bool financialExpanded = false;
  bool techSpecsExpanded = false;
  bool attachmentsExpanded = false;
  bool tagsExpanded = false;
  bool issuesExpanded = true;
  bool maintenanceExpanded = false;
  bool sapDetailsExpanded = false;
  bool vehicleDetailsExpanded = false;
  bool remindersExpanded = true;
  bool commentsExpanded = true;
  bool transactionHistoryExpanded = true;
  bool warrantyExpanded = true;

  final ImagePicker _picker = ImagePicker();

  void _showFullImage(String imagePath) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(10),
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: InteractiveViewer(
              panEnabled: false,
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 4,
              child: Image.file(File(imagePath)),
            ),
          ),
        );
      },
    );
  }

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

  void _handleTagging() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => QRScannerPage(onScan: (qrCode) async {
        final qrCodeImagePath = await QrCodeService.generateAndSaveQrCode(
            qrCode,
            fileName: "qr_code_${widget.item.id}.png");
        final updatedItem = widget.item.copyWith(
          qrCodeId: qrCode,
          qrCodeUrl: qrCodeImagePath,
          isTagged: true,
        );
        widget.onUpdateItem(updatedItem);
      }),
    ));
  }

  void _handleEditItem() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditItemWidget(
          item: widget.item,
          onClose: () => Navigator.of(context).pop(),
          onSave: (updatedItem) {
            Provider.of<LocalDataStore>(context, listen: false)
                .updateItem(updatedItem);
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  void _handleRaiseIssue() {
    final dataStore = Provider.of<LocalDataStore>(context, listen: false);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ChangeNotifierProvider.value(
          value: dataStore,
          child: DraggableScrollableSheet(
            initialChildSize: 0.8,
            maxChildSize: 0.8,
            minChildSize: 0.5,
            builder: (_, controller) => RaiseIssueWidget(
              itemId: widget.item.id,
              onClose: () => Navigator.of(context).pop(),
            ),
          ),
        );
      },
    );
  }

  void _handleCheckout() {
    final dataStore = Provider.of<LocalDataStore>(context, listen: false);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ChangeNotifierProvider.value(
          value: dataStore,
          child: CheckoutWidget(
            itemDepartment: widget.item.department ?? 'N/A',
            onClose: () => Navigator.of(context).pop(),
            onSave: (assignTo, Uint8List? assigneeSignature,
                Uint8List? operatorSignature) async {
              dataStore.checkoutItem(
                widget.item.id,
                assignTo,
                assigneeSignature: assigneeSignature,
                operatorSignature: operatorSignature,
              );
              Navigator.of(context).pop();
            },
          ),
        );
      },
    );
  }

  void _handleCheckin() {
    final dataStore = Provider.of<LocalDataStore>(context, listen: false);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ChangeNotifierProvider.value(
          value: dataStore,
          child: CheckinWidget(
            onClose: () => Navigator.of(context).pop(),
            onSave: ({
              required isWriteOff,
              required condition,
              required assignedStaff,
              required attachment,
              required Uint8List? staffSignature,
              required Uint8List? operatorSignature,
            }) async {
              if (isWriteOff) {
                dataStore.updateItem(widget.item
                    .copyWith(isWrittenOff: true, isAvailable: false));
              } else {
                dataStore.checkinItem(widget.item.id,
                    assigneeSignature: staffSignature,
                    operatorSignature: operatorSignature);
              }
              Navigator.of(context).pop();
            },
            assignedStaff: widget.item.assignedStaff,
          ),
        );
      },
    );
  }

  void _handleScheduleMaintenance() async {
    final dataStore = Provider.of<LocalDataStore>(context, listen: false);
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: widget.item.nextMaintenanceDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      final updatedItem = widget.item.copyWith(nextMaintenanceDate: pickedDate);
      dataStore.updateItem(updatedItem);
    }
  }

  void _handleSetWarrantyExpiry() async {
    final dataStore = Provider.of<LocalDataStore>(context, listen: false);
    final currentItem =
        dataStore.items.firstWhere((i) => i.id == widget.item.id);

    final providerController =
        TextEditingController(text: currentItem.warranty?.provider);
    DateTime? selectedDate = currentItem.warranty?.expiryDate;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Set Warranty Information'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: providerController,
                    decoration:
                        const InputDecoration(labelText: 'Warranty Provider'),
                  ),
                  const SizedBox(height: 20),
                  Text(selectedDate == null
                      ? 'No date selected'
                      : "${selectedDate!.toLocal()}".split(' ')[0]),
                  ElevatedButton(
                    child: const Text('Select Expiry Date'),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2101),
                      );
                      if (picked != null) {
                        setDialogState(() => selectedDate = picked);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    final newWarranty = Warranty(
                      provider: providerController.text.trim(),
                      expiryDate: selectedDate,
                    );

                    final updatedItem =
                        currentItem.copyWith(warranty: newWarranty);
                    dataStore.updateItem(updatedItem);
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _logMaintenanceEvent(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final descriptionController = TextEditingController();
    final vendorController = TextEditingController();
    final costController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Log Maintenance Event'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                        controller: descriptionController,
                        decoration:
                            const InputDecoration(labelText: 'Description'),
                        validator: (value) =>
                            value!.isEmpty ? 'Required' : null),
                    TextFormField(
                        controller: vendorController,
                        decoration: const InputDecoration(labelText: 'Vendor'),
                        validator: (value) =>
                            value!.isEmpty ? 'Required' : null),
                    TextFormField(
                        controller: costController,
                        decoration: const InputDecoration(
                            labelText: 'Cost (e.g., 100.00)'),
                        keyboardType: TextInputType.number,
                        validator: (value) => double.tryParse(value!) == null
                            ? 'Invalid number'
                            : null),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    setDialogState(() => isLoading = true);
                    try {
                      final newLog = MaintenanceLog(
                        id: 'log_${DateTime.now().millisecondsSinceEpoch}',
                        itemId: widget.item.id,
                        description: descriptionController.text.trim(),
                        vendor: vendorController.text.trim(),
                        cost: double.parse(costController.text.trim()),
                        maintenanceDate: DateTime.now(),
                      );
                      print('Maintenance Logged: ${newLog.description}');
                      widget.onUpdateItem(widget.item
                          .copyWith(lastMaintenanceDate: DateTime.now()));
                      Navigator.of(context).pop();
                    } catch (e) {
                      setDialogState(() => isLoading = false);
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text(e.toString())));
                    }
                  },
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Log Event'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _pickAttachment() async {
    final XFile? image =
        await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (image != null) {
      // Placeholder for attachment logic
    }
  }

  void _showAddReminderDialog() {
    final nameController = TextEditingController();
    DateTime? selectedDate;
    RepeatFrequency selectedRepeat = RepeatFrequency.none;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Reminder'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                        controller: nameController,
                        decoration:
                            const InputDecoration(labelText: 'Reminder Name')),
                    const SizedBox(height: 20),
                    Text(selectedDate == null
                        ? 'No date selected'
                        : "${selectedDate!.toLocal()}".split(' ')[0]),
                    ElevatedButton(
                      child: const Text('Select Date and Time'),
                      onPressed: () async {
                        final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2101));
                        if (date == null) return;
                        final time = await showTimePicker(
                            context: context,
                            initialTime:
                                TimeOfDay.fromDateTime(DateTime.now()));
                        if (time == null) return;
                        setDialogState(() {
                          selectedDate = DateTime(date.year, date.month,
                              date.day, time.hour, time.minute);
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<RepeatFrequency>(
                      value: selectedRepeat,
                      decoration: const InputDecoration(labelText: 'Repeat'),
                      items: RepeatFrequency.values
                          .map((freq) => DropdownMenuItem(
                              value: freq, child: Text(freq.name)))
                          .toList(),
                      onChanged: (val) => setDialogState(
                          () => selectedRepeat = val ?? RepeatFrequency.none),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.isNotEmpty &&
                        selectedDate != null) {
                      final dataStore =
                          Provider.of<LocalDataStore>(context, listen: false);
                      dataStore.addReminder(Reminder(
                        id: 'rem_${DateTime.now().millisecondsSinceEpoch}',
                        itemId: widget.item.id,
                        name: nameController.text,
                        dateTime: selectedDate!,
                        repeat: selectedRepeat,
                      ));
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddCommentDialog() {
    final commentController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Comment'),
        content: TextField(
          controller: commentController,
          decoration: const InputDecoration(hintText: 'Write a comment...'),
          maxLines: 4,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (commentController.text.isNotEmpty) {
                final dataStore =
                    Provider.of<LocalDataStore>(context, listen: false);
                dataStore.addComment(Comment(
                  id: 'com_${DateTime.now().millisecondsSinceEpoch}',
                  itemId: widget.item.id,
                  description: commentController.text,
                  authorEmail: dataStore.currentUser.email,
                  timestamp: DateTime.now(),
                ));
                Navigator.pop(context);
              }
            },
            child: const Text('Post'),
          ),
        ],
      ),
    );
  }

  void _showUpdateIssueStatusDialog(Issue issue) {
    showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Update Issue Status'),
          children: [
            SimpleDialogOption(
                onPressed: () {
                  Provider.of<LocalDataStore>(context, listen: false)
                      .updateIssueStatus(issue.issueId, IssueStatus.Fixed);
                  Navigator.pop(context);
                },
                child: const Text('Fixed')),
            SimpleDialogOption(
                onPressed: () {
                  Provider.of<LocalDataStore>(context, listen: false)
                      .updateIssueStatus(issue.issueId, IssueStatus.NotAnIssue);
                  Navigator.pop(context);
                },
                child: const Text('Not an Issue')),
            SimpleDialogOption(
                onPressed: () {
                  Provider.of<LocalDataStore>(context, listen: false)
                      .updateIssueStatus(
                          issue.issueId, IssueStatus.CreatedByError);
                  Navigator.pop(context);
                },
                child: const Text('Created by Error')),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataStore = Provider.of<LocalDataStore>(context);
    final currentItem = dataStore.items.firstWhere(
        (item) => item.id == widget.item.id,
        orElse: () => widget.item);

    final itemIssues =
        dataStore.issues.where((i) => i.itemId == currentItem.id).toList();
    final itemReminders =
        dataStore.reminders.where((r) => r.itemId == currentItem.id).toList();
    final itemComments =
        dataStore.comments.where((c) => c.itemId == currentItem.id).toList();
    final itemHistory =
        dataStore.history.where((h) => h.targetId == currentItem.id).toList();

    bool isVehicle = currentItem.assetClassDesc == 'Company Vehicle (Own Used)';

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.grey[100],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.black),
            onPressed: _handleEditItem,
            tooltip: 'Edit Item',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: currentItem.imageUrl != null &&
                            File(currentItem.imageUrl!).existsSync()
                        ? GestureDetector(
                            onTap: () => _showFullImage(currentItem.imageUrl!),
                            child: Image.file(
                              File(currentItem.imageUrl!),
                              fit: BoxFit.cover,
                            ),
                          )
                        : Container(
                            color: Colors.grey[300],
                            child: Center(
                                child: buildItemIcon(currentItem.itemType)),
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(currentItem.name,
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(currentItem.category,
                          style:
                              TextStyle(fontSize: 16, color: Colors.grey[600])),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                if (currentItem.isAvailable)
                  Expanded(
                      child: _buildActionButton(
                          icon: Icons.shopping_cart_checkout_outlined,
                          text: 'Checkout',
                          onPressed: _handleCheckout))
                else
                  Expanded(
                      child: _buildActionButton(
                          icon: Icons.assignment_return_outlined,
                          text: 'Check In',
                          onPressed: _handleCheckin)),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildActionButton(
                        icon: Icons.report_problem_outlined,
                        text: 'Raise Issue',
                        onPressed: _handleRaiseIssue)),
              ],
            ),
            const SizedBox(height: 24),
            _buildExpandableSection(
              title: 'Status & Location',
              subtitle: 'Current status, condition, and assignment',
              isExpanded: detailsExpanded,
              onTap: () => setState(() => detailsExpanded = !detailsExpanded),
              expandedContent: _buildDetailsGrid(currentItem),
            ),
            _buildExpandableSection(
              title: 'Purchase Details',
              subtitle: 'Supplier and purchase information',
              isExpanded: financialExpanded,
              onTap: () =>
                  setState(() => financialExpanded = !financialExpanded),
              expandedContent: _buildFinancialGrid(currentItem),
            ),
            _buildExpandableSection(
              title: 'Warranty Information',
              subtitle: 'View and manage warranty details',
              isExpanded: warrantyExpanded,
              onTap: () => setState(() => warrantyExpanded = !warrantyExpanded),
              expandedContent: _buildWarrantySection(currentItem),
            ),
            _buildExpandableSection(
              title: 'SAP Details',
              subtitle: 'ERP and asset tracking data',
              isExpanded: sapDetailsExpanded,
              onTap: () =>
                  setState(() => sapDetailsExpanded = !sapDetailsExpanded),
              expandedContent: _buildSapDetailsGrid(currentItem),
            ),
            if (isVehicle)
              _buildExpandableSection(
                title: 'Vehicle Details',
                subtitle: 'Specific information for vehicles',
                isExpanded: vehicleDetailsExpanded,
                onTap: () => setState(
                    () => vehicleDetailsExpanded = !vehicleDetailsExpanded),
                expandedContent: _buildVehicleDetailsGrid(currentItem),
              ),
            _buildExpandableSection(
              title: 'Technical Specs',
              subtitle: 'Model, serial number, and other identifiers',
              isExpanded: techSpecsExpanded,
              onTap: () =>
                  setState(() => techSpecsExpanded = !techSpecsExpanded),
              expandedContent: _buildTechSpecsGrid(currentItem),
            ),
            _buildExpandableSection(
              title: 'Issues (${itemIssues.length})',
              subtitle: 'Reported problems for this item',
              isExpanded: issuesExpanded,
              onTap: () => setState(() => issuesExpanded = !issuesExpanded),
              expandedContent: Column(
                children: itemIssues.isEmpty
                    ? [
                        const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20.0),
                            child: Center(
                                child:
                                    Text("No issues reported for this item.")))
                      ]
                    : itemIssues.map((issue) {
                        final reporter = dataStore.users.firstWhere(
                            (user) => user.id == issue.reporterId,
                            orElse: () => LocalUser(
                                id: '',
                                name: 'Unknown User',
                                email: '',
                                roleId: '',
                                department: ''));
                        return Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(issue.description),
                            subtitle: Text('Priority: ${issue.priority.name}'),
                            trailing: Text(issue.status.name,
                                style: TextStyle(
                                    color: issue.status == IssueStatus.Open
                                        ? Colors.red
                                        : Colors.green)),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => IssueDetailsScreen(
                                    issue: issue,
                                    reporter: reporter,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      }).toList(),
              ),
            ),
            _buildExpandableSection(
              title: 'Reminders (${itemReminders.length})',
              subtitle: 'Scheduled maintenance and other reminders',
              isExpanded: remindersExpanded,
              onTap: () =>
                  setState(() => remindersExpanded = !remindersExpanded),
              expandedContent: Column(
                children: [
                  ...itemReminders.map((reminder) => Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(reminder.name),
                          subtitle: Text(
                              "Due: ${reminder.dateTime.toLocal().toString().split('.')[0]}"),
                          trailing: Text(reminder.repeat.name),
                        ),
                      )),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _showAddReminderDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Reminder'),
                    ),
                  ),
                ],
              ),
            ),
            _buildExpandableSection(
              title: 'Comments (${itemComments.length})',
              subtitle: 'Notes and history for this item',
              isExpanded: commentsExpanded,
              onTap: () => setState(() => commentsExpanded = !commentsExpanded),
              expandedContent: Column(
                children: [
                  ...itemComments.map((comment) => Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(comment.description),
                          subtitle: Text(
                              'By: ${comment.authorEmail} on ${comment.timestamp.toLocal().toString().split(' ')[0]}'),
                        ),
                      )),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _showAddCommentDialog,
                      icon: const Icon(Icons.add_comment_outlined),
                      label: const Text('Add Comment'),
                    ),
                  ),
                ],
              ),
            ),
            _buildExpandableSection(
                title: 'Transaction History',
                subtitle: 'View check-in/checkout events and signatures',
                isExpanded: transactionHistoryExpanded,
                onTap: () => setState(() =>
                    transactionHistoryExpanded = !transactionHistoryExpanded),
                expandedContent: itemHistory.isEmpty
                    ? const Center(
                        child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 20.0),
                            child:
                                Text('No transaction history for this item.')))
                    : Column(
                        children: itemHistory
                            .map((entry) =>
                                _buildHistoryCardWithSignatures(entry))
                            .toList(),
                      )),
            _buildExpandableSection(
              title: 'Attachments',
              subtitle: 'View and add photos or documents',
              isExpanded: attachmentsExpanded,
              onTap: () =>
                  setState(() => attachmentsExpanded = !attachmentsExpanded),
              expandedContent: Column(
                children: [
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _pickAttachment,
                      icon: const Icon(Icons.add_a_photo_outlined),
                      label: const Text('Add Photo'),
                    ),
                  ),
                ],
              ),
            ),
            _buildExpandableSection(
              title: 'Maintenance',
              subtitle: 'Schedule and track maintenance',
              isExpanded: maintenanceExpanded,
              onTap: () =>
                  setState(() => maintenanceExpanded = !maintenanceExpanded),
              expandedContent: _buildMaintenanceGrid(currentItem),
            ),
            _buildExpandableSection(
              title: 'Tags',
              subtitle: 'Manage QR code assignment for this item',
              isExpanded: tagsExpanded,
              onTap: () => setState(() => tagsExpanded = !tagsExpanded),
              expandedContent: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentItem.isTagged
                        ? 'Tagged with QR Code:'
                        : 'This item is not yet tagged.',
                    style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                  ),
                  if (currentItem.isTagged)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding:
                              const EdgeInsets.only(top: 8.0, bottom: 16.0),
                          child: Text(currentItem.qrCodeId ?? 'N/A',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                        if (currentItem.qrCodeUrl != null)
                          Column(
                            children: [
                              SizedBox(
                                height: 180,
                                child: Image.file(
                                  File(currentItem.qrCodeUrl!),
                                  fit: BoxFit.contain,
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    final file = File(currentItem.qrCodeUrl!);
                                    if (await file.exists()) {
                                      final bytes = await file.readAsBytes();
                                      final result =
                                          await ImageGallerySaverPlus.saveImage(
                                              bytes,
                                              quality: 100,
                                              name:
                                                  "qr_code_${currentItem.id}");
                                      final isSuccess =
                                          result['isSuccess'] == true;
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(isSuccess
                                              ? 'QR code saved to Gallery.'
                                              : 'Failed to save QR code.'),
                                          backgroundColor: isSuccess
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.download),
                                  label: const Text('Download QR Code'),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _handleTagging,
                      icon: const Icon(Icons.qr_code_scanner),
                      label: Text(currentItem.isTagged
                          ? 'Scan to Re-Tag'
                          : 'Scan to Tag'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCardWithSignatures(HistoryEntry entry) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: Icon(entry.icon),
              title: Text(entry.title),
              subtitle: Text(entry.description),
              trailing: Text("${entry.timestamp.toLocal()}".split(' ')[0]),
            ),
            if (entry.assigneeSignature != null ||
                entry.operatorSignature != null)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    if (entry.assigneeSignature != null)
                      _buildSignatureThumbnail(
                          'Assignee', entry.assigneeSignature!),
                    if (entry.operatorSignature != null)
                      _buildSignatureThumbnail(
                          'Operator', entry.operatorSignature!),
                  ],
                ),
              )
          ],
        ),
      ),
    );
  }

  Widget _buildSignatureThumbnail(String label, Uint8List signatureBytes) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        InkWell(
          onTap: () => _showFullSignatureImage(signatureBytes),
          child: Container(
            width: 100,
            height: 50,
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

  Widget _buildDetailsGrid(ItemModel currentItem) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 3.5,
      children: [
        _buildDetailItem(
            "Status", currentItem.isWrittenOff ? "Written Off" : "Active"),
        _buildDetailItem("Department", currentItem.department ?? 'N/A'),
        _buildDetailItem("Assigned To", currentItem.assignedStaff ?? 'N/A'),
        _buildDetailItem("Available", currentItem.isAvailable ? "Yes" : "No"),
      ],
    );
  }

  Widget _buildSapDetailsGrid(ItemModel currentItem) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 3.5,
      children: [
        _buildDetailItem("CoCD", currentItem.coCd ?? 'N/A'),
        _buildDetailItem("Class", currentItem.sapClass ?? 'N/A'),
        _buildDetailItem(
            "Asset Class Desc", currentItem.assetClassDesc ?? 'N/A'),
        _buildDetailItem("APC Acct", currentItem.apcAcct ?? 'N/A'),
        _buildDetailItem("Vendor", currentItem.vendor ?? 'N/A'),
        _buildDetailItem("Plnt", currentItem.plnt ?? 'N/A'),
        _buildDetailItem("Asset Type", currentItem.assetType ?? 'N/A'),
        _buildDetailItem("Owner", currentItem.owner ?? 'N/A'),
      ],
    );
  }

  Widget _buildVehicleDetailsGrid(ItemModel currentItem) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 3.5,
      children: [
        _buildDetailItem("Vehicle ID No.", currentItem.vehicleIdNo ?? 'N/A'),
        _buildDetailItem("LIC Plate", currentItem.licPlate ?? 'N/A'),
        _buildDetailItem("Vehicle Model", currentItem.vehicleModel ?? 'N/A'),
        _buildDetailItem("Model Code", currentItem.modelCode ?? 'N/A'),
        _buildDetailItem("Model Description", currentItem.modelDesc ?? 'N/A'),
        _buildDetailItem("Model Year", currentItem.modelYear ?? 'N/A'),
      ],
    );
  }

  Widget _buildFinancialGrid(ItemModel currentItem) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 3.5,
      children: [
        _buildDetailItem("Purchase Date",
            "${currentItem.purchaseDate.day}/${currentItem.purchaseDate.month}/${currentItem.purchaseDate.year}"),
        _buildDetailItem("Supplier", currentItem.supplier),
        _buildDetailItem("Purchase Price",
            'QR ${currentItem.purchasePrice?.toStringAsFixed(2) ?? 'N/A'}'),
        _buildDetailItem("Current Value",
            'QR ${currentItem.currentValue?.toStringAsFixed(2) ?? 'N/A'}'),
      ],
    );
  }

  Widget _buildWarrantySection(ItemModel currentItem) {
    final expiryDate = currentItem.warranty?.expiryDate;
    final provider = currentItem.warranty?.provider ?? 'N/A';

    return Column(
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 3.5,
          children: [
            _buildDetailItem("Warranty Provider", provider),
            _buildDetailItem("Expires On",
                expiryDate?.toLocal().toString().split(' ')[0] ?? 'N/A'),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _handleSetWarrantyExpiry,
            icon: const Icon(Icons.calendar_month_outlined),
            label: const Text('Set/Update Warranty'),
          ),
        ),
      ],
    );
  }

  Widget _buildMaintenanceGrid(ItemModel currentItem) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 3.5,
          children: [
            _buildDetailItem(
                "Last Maintenance",
                currentItem.lastMaintenanceDate?.toString().split(' ')[0] ??
                    'N/A'),
            _buildDetailItem(
                "Next Maintenance",
                currentItem.nextMaintenanceDate?.toString().split(' ')[0] ??
                    'N/A'),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _handleScheduleMaintenance,
            icon: const Icon(Icons.calendar_month_outlined),
            label: const Text('Schedule Next Maintenance'),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _logMaintenanceEvent(context),
            icon: const Icon(Icons.build_outlined),
            label: const Text('Log Maintenance Event'),
          ),
        ),
        const SizedBox(height: 24),
        const Text('Maintenance History',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87)),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 0,
          itemBuilder: (context, index) {
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _buildTechSpecsGrid(ItemModel currentItem) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 3.5,
      children: [
        _buildDetailItem("Model Code", currentItem.modelCode ?? 'N/A'),
        _buildDetailItem("Model Description", currentItem.modelDesc ?? 'N/A'),
        _buildDetailItem("Model Year", currentItem.modelYear ?? 'N/A'),
      ],
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          const SizedBox(height: 4),
          Text(value,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildActionButton(
      {required IconData icon,
      required String text,
      required VoidCallback onPressed}) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: Colors.black87),
              const SizedBox(width: 8),
              Text(text,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandableSection(
      {required String title,
      required String subtitle,
      required bool isExpanded,
      required VoidCallback onTap,
      Widget? expandedContent}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12), topRight: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(subtitle,
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                  Icon(isExpanded ? Icons.remove : Icons.add),
                ],
              ),
            ),
          ),
          if (isExpanded && expandedContent != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12)),
              ),
              child: expandedContent,
            ),
        ],
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
    default:
      iconData = Icons.inventory;
      color = Colors.grey;
  }
  return Icon(iconData, size: 40, color: color);
}
