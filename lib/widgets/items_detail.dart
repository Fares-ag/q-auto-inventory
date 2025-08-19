// lib/widgets/items_detail.dart

// Import necessary packages from Flutter and other libraries.
import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/item_model.dart';
import 'package:flutter_application_1/widgets/checkout.dart';
import 'package:flutter_application_1/widgets/raise_issue.dart';
import 'package:flutter_application_1/widgets/checkin_widget.dart';
import 'package:flutter_application_1/models/issue_model.dart';
import 'package:flutter_application_1/services/local_data_store.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_application_1/models/maintenance_log.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:flutter_application_1/services/qr_code_service.dart';

/// Data model for a single maintenance log entry.
class MaintenanceLog {
  final String id;
  final String itemId;
  final String description;
  final String vendor;
  final double cost;
  final DateTime maintenanceDate;

  MaintenanceLog({
    required this.id,
    required this.itemId,
    required this.description,
    required this.vendor,
    required this.cost,
    required this.maintenanceDate,
  });
}

/// Data model for a comment.
class Comment {
  final String text;
  final String author;
  final DateTime timestamp;
  Comment({required this.text, required this.author, required this.timestamp});
}

/// Data model for an attachment, like a photo or document.
class Attachment {
  final String name;
  final File file;
  final DateTime timestamp;
  Attachment({required this.name, required this.file, required this.timestamp});
}

/// Data model for generic information entries.
class Information {
  final String title;
  final String body;
  final DateTime timestamp;
  Information(
      {required this.title, required this.body, required this.timestamp});
}

/// Data model for an assignment of an item to a user and location.
class Assignment {
  final String staffName;
  final String location;
  final DateTime timestamp;
  Assignment(
      {required this.staffName,
      required this.location,
      required this.timestamp});
}

/// A widget that provides a form for assigning an item to a user.
class AssignToUserWidget extends StatefulWidget {
  final Function(Assignment)
      onSave; // Callback function when the form is saved.
  final VoidCallback onClose; // Callback function to close the widget.
  const AssignToUserWidget(
      {Key? key, required this.onSave, required this.onClose})
      : super(key: key);

  @override
  State<AssignToUserWidget> createState() => _AssignToUserWidgetState();
}

class _AssignToUserWidgetState extends State<AssignToUserWidget> {
  final _formKey = GlobalKey<FormState>(); // Key to manage the form's state.
  final _staffNameController = TextEditingController();
  final _locationController = TextEditingController();
  bool _isLoading = false; // Flag to show a loading indicator on save.

  @override
  void dispose() {
    // Clean up controllers when the widget is removed from the widget tree.
    _staffNameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  /// Validates the form and saves the new assignment.
  void _saveAssignment() {
    // Don't proceed if the form is not valid.
    if (!_formKey.currentState!.validate()) return;

    // Set loading state to true to show progress indicator.
    setState(() {
      _isLoading = true;
    });

    // Create a new Assignment object from the form fields.
    final newAssignment = Assignment(
        staffName: _staffNameController.text.trim(),
        location: _locationController.text.trim(),
        timestamp: DateTime.now());

    // Simulate a network request delay.
    Future.delayed(const Duration(milliseconds: 500), () {
      widget.onSave(newAssignment); // Execute the save callback.
      // Check if the widget is still mounted before updating state.
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      widget.onClose(); // Close the assignment widget.
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Assign To User',
                        style: TextStyle(
                            fontSize: 28, fontWeight: FontWeight.bold)),
                    IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: widget.onClose),
                  ],
                ),
                const SizedBox(height: 30),
                TextFormField(
                    controller: _staffNameController,
                    decoration: const InputDecoration(labelText: 'Staff Name'),
                    validator: (val) =>
                        val!.isEmpty ? 'Please enter a name' : null),
                const SizedBox(height: 20),
                TextFormField(
                    controller: _locationController,
                    decoration: const InputDecoration(labelText: 'Location'),
                    validator: (val) =>
                        val!.isEmpty ? 'Please enter a location' : null),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    // Disable the button while loading.
                    onPressed: _isLoading ? null : _saveAssignment,
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Save Assignment'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A screen that uses the device camera to scan a QR code.
class QRScannerPage extends StatefulWidget {
  final Function(String) onScan; // Callback with the scanned QR code value.
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
          // Scan frame overlay
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
          // Scan indicator/message
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Align QR code within the frame',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The main screen widget that displays all details for a specific item.
class ItemDetailsScreen extends StatefulWidget {
  final ItemModel item; // The item data to display.
  final Function(ItemModel)
      onUpdateItem; // Callback to update the item's state in the parent widget.

  const ItemDetailsScreen({
    Key? key,
    required this.item,
    required this.onUpdateItem,
  }) : super(key: key);

  @override
  State<ItemDetailsScreen> createState() => _ItemDetailsScreenState();
}

class _ItemDetailsScreenState extends State<ItemDetailsScreen> {
  // State variables to control the visibility of expandable sections.
  bool detailsExpanded = true;
  bool financialExpanded = false;
  bool techSpecsExpanded = false;
  bool attachmentsExpanded = false;
  bool tagsExpanded = false;
  bool issuesExpanded = false;
  bool maintenanceExpanded = false;
  bool sapDetailsExpanded = false;
  bool vehicleDetailsExpanded = false;

  // Instance of the local data store for persistence.
  final LocalDataStore _dataStore = LocalDataStore();

  // Lists to hold dynamic data for the item.
  List<Issue> reportedIssues = [];
  List<Attachment> attachments = [];
  final ImagePicker _picker = ImagePicker(); // Instance for picking images.

  /// Navigates to the QR scanner page and updates the item with the scanned code.
  void _handleTagging() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => QRScannerPage(onScan: (qrCode) async {
        // Generate and save QR code image, then update item.
        final qrCodeImagePath = await QrCodeService.generateAndSaveQrCode(
            qrCode,
            fileName: "qr_code_${widget.item.id}.png");
        final updatedItem = widget.item.copyWith(
          qrCodeId: qrCode,
          qrCodeUrl: qrCodeImagePath,
          isTagged: true,
        );
        widget.onUpdateItem(updatedItem);
        Navigator.of(context).pop();
      }),
    ));
  }

  /// Shows a modal bottom sheet to raise a new issue for the item.
  void _handleRaiseIssue() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          maxChildSize: 0.8,
          minChildSize: 0.5,
          builder: (_, controller) => RaiseIssueWidget(
            itemId: widget.item.id,
            onClose: () => Navigator.of(context).pop(),
          ),
        );
      },
    );
  }

  /// Shows a modal bottom sheet for checking out the item.
  void _handleCheckout() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return CheckoutWidget(
          onClose: () => Navigator.of(context).pop(),
          onSave: (assignTo, assigneeSignature, operatorSignature) async {
            // Persist the checkout action.
            _dataStore.checkoutItem(widget.item.id, assignTo);
            // Create an updated item model with the new state.
            final updatedItem = widget.item.copyWith(
              assignedStaff: assignTo,
              isAvailable: false,
            );
            // Update the parent widget's state.
            widget.onUpdateItem(updatedItem);
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  /// Shows a modal bottom sheet for checking in the item.
  void _handleCheckin() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return CheckinWidget(
          onClose: () => Navigator.of(context).pop(),
          onSave: ({
            required isWriteOff,
            required condition,
            required assignedStaff,
            required attachment,
            required staffSignature,
            required operatorSignature,
          }) async {
            // Persist the check-in action.
            _dataStore.checkinItem(widget.item.id);
            // Create an updated item model.
            final updatedItem = widget.item.copyWith(
              isAvailable: !isWriteOff,
              assignedStaff: null,
              isWrittenOff: isWriteOff,
            );
            // Update the parent widget's state.
            widget.onUpdateItem(updatedItem);
            Navigator.of(context).pop();
          },
          assignedStaff: widget.item.assignedStaff,
        );
      },
    );
  }

  /// Shows a date picker to schedule the next maintenance date.
  void _handleScheduleMaintenance() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: widget.item.nextMaintenanceDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      // If a date was picked, update the item.
      final updatedItem = widget.item.copyWith(nextMaintenanceDate: pickedDate);
      _dataStore.updateItem(updatedItem);
      widget.onUpdateItem(updatedItem);
    }
  }

  /// Shows a dialog to log a new maintenance event.
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
                      validator: (value) => value!.isEmpty ? 'Required' : null,
                    ),
                    TextFormField(
                      controller: vendorController,
                      decoration: const InputDecoration(labelText: 'Vendor'),
                      validator: (value) => value!.isEmpty ? 'Required' : null,
                    ),
                    TextFormField(
                      controller: costController,
                      decoration: const InputDecoration(
                          labelText: 'Cost (e.g., 100.00)'),
                      keyboardType: TextInputType.number,
                      validator: (value) => double.tryParse(value!) == null
                          ? 'Invalid number'
                          : null,
                    ),
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
                      // TODO: Persist the newLog object.
                      print('Maintenance Logged: ${newLog.description}');

                      // Update the item's last maintenance date.
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

  /// Uses the image picker to take a photo with the camera and add it as an attachment.
  void _pickAttachment() async {
    final XFile? image =
        await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (image != null) {
      // If an image was captured, add it to the attachments list.
      setState(() {
        attachments.add(
          Attachment(
            name: 'Photo_${DateTime.now().millisecondsSinceEpoch}.jpg',
            file: File(image.path),
            timestamp: DateTime.now(),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // DEBUG: Log the entire item body for inspection
    print('[ItemDetailsScreen] ItemModel: ${widget.item.toString()}');
    // Check if the item is a vehicle to conditionally show vehicle details.
    bool isVehicle = widget.item.assetClassDesc == 'Company Vehicle (Own Used)';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header Section ---
            Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey[300]),
                  child: Center(child: buildItemIcon(widget.item.itemType)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.item.name,
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(widget.item.category,
                          style:
                              TextStyle(fontSize: 16, color: Colors.grey[600])),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // --- Action Buttons Section ---
            Row(
              children: [
                // Conditionally show 'Checkout' or 'Check In' button.
                if (widget.item.isAvailable)
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
            // --- Expandable Details Sections ---
            _buildExpandableSection(
              title: 'Status & Location',
              subtitle: 'Current status, condition, and assignment',
              isExpanded: detailsExpanded,
              onTap: () => setState(() => detailsExpanded = !detailsExpanded),
              expandedContent: _buildDetailsGrid(),
            ),
            _buildExpandableSection(
              title: 'Purchase Details',
              subtitle: 'Supplier and purchase information',
              isExpanded: financialExpanded,
              onTap: () =>
                  setState(() => financialExpanded = !financialExpanded),
              expandedContent: _buildFinancialGrid(),
            ),
            _buildExpandableSection(
              title: 'SAP Details',
              subtitle: 'ERP and asset tracking data',
              isExpanded: sapDetailsExpanded,
              onTap: () =>
                  setState(() => sapDetailsExpanded = !sapDetailsExpanded),
              expandedContent: _buildSapDetailsGrid(),
            ),
            // Conditionally render the Vehicle Details section.
            if (isVehicle)
              _buildExpandableSection(
                title: 'Vehicle Details',
                subtitle: 'Specific information for vehicles',
                isExpanded: vehicleDetailsExpanded,
                onTap: () => setState(
                    () => vehicleDetailsExpanded = !vehicleDetailsExpanded),
                expandedContent: _buildVehicleDetailsGrid(),
              ),
            _buildExpandableSection(
              title: 'Technical Specs',
              subtitle: 'Model, serial number, and other identifiers',
              isExpanded: techSpecsExpanded,
              onTap: () =>
                  setState(() => techSpecsExpanded = !techSpecsExpanded),
              expandedContent: _buildTechSpecsGrid(),
            ),
            _buildExpandableSection(
              title: 'Attachments',
              subtitle: 'View and add photos or documents',
              isExpanded: attachmentsExpanded,
              onTap: () =>
                  setState(() => attachmentsExpanded = !attachmentsExpanded),
              expandedContent: Column(
                children: [
                  // Map the list of attachments to card widgets.
                  ...attachments
                      .map((attachment) => _buildAttachmentCard(attachment))
                      .toList(),
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
              expandedContent: _buildMaintenanceGrid(),
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
                    widget.item.isTagged
                        ? 'Tagged with QR Code:'
                        : 'This item is not yet tagged.',
                    style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                  ),
                  if (widget.item.isTagged)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding:
                              const EdgeInsets.only(top: 8.0, bottom: 16.0),
                          child: Text(widget.item.qrCodeId ?? 'N/A',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                        if (widget.item.qrCodeUrl != null)
                          Column(
                            children: [
                              SizedBox(
                                height: 180,
                                child: Image.file(
                                  File(widget.item.qrCodeUrl!),
                                  fit: BoxFit.contain,
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    // Save QR code image to device gallery
                                    final file = File(widget.item.qrCodeUrl!);
                                    if (await file.exists()) {
                                      final bytes = await file.readAsBytes();
                                      final result =
                                          await ImageGallerySaver.saveImage(
                                              bytes,
                                              quality: 100,
                                              name:
                                                  "qr_code_${widget.item.id}");
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
                      label: Text(widget.item.isTagged
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

  /// Builds a grid to display the item's status and location details.
  Widget _buildDetailsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 3.5,
      children: [
        _buildDetailItem(
            "Status", widget.item.isWrittenOff ? "Written Off" : "Active"),
        _buildDetailItem("Department", widget.item.department ?? 'N/A'),
        _buildDetailItem("Assigned To", widget.item.assignedStaff ?? 'N/A'),
        _buildDetailItem("Available", widget.item.isAvailable ? "Yes" : "No"),
      ],
    );
  }

  /// Builds a grid to display SAP-related details.
  Widget _buildSapDetailsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 3.5,
      children: [
        _buildDetailItem("CoCD", widget.item.coCd ?? 'N/A'),
        _buildDetailItem("Class", widget.item.sapClass ?? 'N/A'),
        _buildDetailItem(
            "Asset Class Desc", widget.item.assetClassDesc ?? 'N/A'),
        _buildDetailItem("APC Acct", widget.item.apcAcct ?? 'N/A'),
        _buildDetailItem("Vendor", widget.item.vendor ?? 'N/A'),
        _buildDetailItem("Plnt", widget.item.plnt ?? 'N/A'),
        _buildDetailItem("Asset Type", widget.item.assetType ?? 'N/A'),
        _buildDetailItem("Owner", widget.item.owner ?? 'N/A'),
      ],
    );
  }

  /// Builds a grid to display vehicle-specific details.
  Widget _buildVehicleDetailsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 3.5,
      children: [
        _buildDetailItem("Vehicle ID No.", widget.item.vehicleIdNo ?? 'N/A'),
        _buildDetailItem("LIC Plate", widget.item.licPlate ?? 'N/A'),
        _buildDetailItem("Vehicle Model", widget.item.vehicleModel ?? 'N/A'),
        _buildDetailItem("Model Code", widget.item.modelCode ?? 'N/A'),
        _buildDetailItem("Model Description", widget.item.modelDesc ?? 'N/A'),
        _buildDetailItem("Model Year", widget.item.modelYear ?? 'N/A'),
      ],
    );
  }

  /// Builds a grid to display financial details like purchase price and date.
  Widget _buildFinancialGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 3.5,
      children: [
        _buildDetailItem("Purchase Date",
            "${widget.item.purchaseDate.day}/${widget.item.purchaseDate.month}/${widget.item.purchaseDate.year}"),
        _buildDetailItem("Supplier", widget.item.supplier),
        _buildDetailItem("Purchase Price",
            'QR ${widget.item.purchasePrice?.toStringAsFixed(2) ?? 'N/A'}'),
        _buildDetailItem("Current Value",
            'QR ${widget.item.currentValue?.toStringAsFixed(2) ?? 'N/A'}'),
      ],
    );
  }

  /// Builds the content for the maintenance section, including dates, actions, and history.
  Widget _buildMaintenanceGrid() {
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
                widget.item.lastMaintenanceDate?.toString().split(' ')[0] ??
                    'N/A'),
            _buildDetailItem(
                "Next Maintenance",
                widget.item.nextMaintenanceDate?.toString().split(' ')[0] ??
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
        const Text(
          'Maintenance History',
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        const SizedBox(height: 16),
        // Placeholder for maintenance history list.
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount:
              0, // TODO: Replace with actual maintenance log list length.
          itemBuilder: (context, index) {
            // TODO: Build and return _buildMaintenanceCard(logList[index]).
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  /// Builds a card widget to display a single maintenance log entry.
  Widget _buildMaintenanceCard(MaintenanceLog log) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const Icon(Icons.build_circle_outlined, color: Colors.blue),
        title: Text(log.description),
        subtitle: Text(
            'Cost: QR ${log.cost.toStringAsFixed(2)} | Vendor: ${log.vendor}'),
        trailing: Text(log.maintenanceDate.toString().split(' ')[0]),
      ),
    );
  }

  /// Builds a grid to display technical specifications.
  Widget _buildTechSpecsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 3.5,
      children: [
        _buildDetailItem("Model Code", widget.item.modelCode ?? 'N/A'),
        _buildDetailItem("Model Description", widget.item.modelDesc ?? 'N/A'),
        _buildDetailItem("Model Year", widget.item.modelYear ?? 'N/A'),
      ],
    );
  }

  /// A reusable helper widget to display a label and a value.
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

  /// A reusable helper widget for creating styled action buttons.
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

  /// A reusable widget for creating a collapsible section.
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
                  // Show add or remove icon based on expanded state.
                  Icon(isExpanded ? Icons.remove : Icons.add),
                ],
              ),
            ),
          ),
          // If expanded, show the content.
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

  /// Builds a card to display a single attachment.
  Widget _buildAttachmentCard(Attachment attachment) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: const Icon(Icons.image, color: Colors.blue),
        title: Text(attachment.name),
        subtitle: Text(
            'Added on ${attachment.timestamp.day}/${attachment.timestamp.month}/${attachment.timestamp.year}'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // TODO: Implement logic to view the attachment.
        },
      ),
    );
  }
}

/// A helper function that returns an icon based on the item type.
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
