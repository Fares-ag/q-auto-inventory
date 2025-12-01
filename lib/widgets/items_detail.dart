import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'package:flutter_application_1/models/item_model.dart';
import 'package:flutter_application_1/models/assignment_model.dart';
import 'package:flutter_application_1/widgets/history_screen.dart';
import 'package:flutter_application_1/widgets/checkout.dart';
import 'package:flutter_application_1/widgets/raise_issue.dart';
import 'package:flutter_application_1/models/history_entry_model.dart';
import 'package:flutter_application_1/models/comment_model.dart';
import 'package:flutter_application_1/models/attachment_model.dart';
import 'package:flutter_application_1/models/information_model.dart';
import 'package:flutter_application_1/config/app_theme.dart';
import 'package:flutter_application_1/services/storage_service.dart';
import 'package:flutter_application_1/services/item_details_service.dart';
import 'package:flutter_application_1/services/firebase_service.dart';
import 'package:flutter_application_1/widgets/common/item_icon_builder.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
// New reusable widgets
import 'package:flutter_application_1/widgets/item_details/expandable_section.dart';
import 'package:flutter_application_1/widgets/item_details/comments_section.dart';
import 'package:flutter_application_1/widgets/item_details/attachments_section.dart';
import 'package:flutter_application_1/widgets/item_details/issues_section.dart';
import 'package:flutter_application_1/widgets/item_details/information_section.dart';
import 'package:flutter_application_1/widgets/item_details/qr_code_section.dart';
import 'package:flutter_application_1/widgets/item_details/item_header.dart';
import 'package:flutter_application_1/widgets/item_details/action_button.dart';
import 'package:flutter_application_1/widgets/common/history_entry_card.dart';

// New widget for assigning an item to a user.
class AssignToUserWidget extends StatefulWidget {
  final Function(Assignment) onSave;
  final VoidCallback onClose;

  const AssignToUserWidget({
    Key? key,
    required this.onSave,
    required this.onClose,
  }) : super(key: key);

  @override
  State<AssignToUserWidget> createState() => _AssignToUserWidgetState();
}

class _AssignToUserWidgetState extends State<AssignToUserWidget> {
  final _formKey = GlobalKey<FormState>();
  final _staffNameController = TextEditingController();
  final _locationController = TextEditingController();
  final _assignedFromController = TextEditingController();
  final _adminController = TextEditingController();
  DateTime? _returnDate;
  TimeOfDay? _returnTime;
  bool _isLoading = false;

  @override
  void dispose() {
    _staffNameController.dispose();
    _locationController.dispose();
    _assignedFromController.dispose();
    _adminController.dispose();
    super.dispose();
  }

  Future<void> _presentDatePicker() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _returnDate ?? now,
      firstDate: now,
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      setState(() {
        _returnDate = pickedDate;
      });
    }
  }

  Future<void> _presentTimePicker() async {
    final now = TimeOfDay.now();
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _returnTime ?? now,
    );
    if (pickedTime != null) {
      setState(() {
        _returnTime = pickedTime;
      });
    }
  }

  void _saveAssignment() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_returnDate == null || _returnTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select return date and time'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Combine date and time
    final returnDateTime = DateTime(
      _returnDate!.year,
      _returnDate!.month,
      _returnDate!.day,
      _returnTime!.hour,
      _returnTime!.minute,
    );

    final newAssignment = Assignment(
      staffName: _staffNameController.text.trim(),
      location: _locationController.text.trim(),
      assignedFrom: _assignedFromController.text.trim(),
      admin: _adminController.text.trim(),
      returnDate: returnDateTime,
      timestamp: DateTime.now(),
    );

    Future.delayed(const Duration(milliseconds: 500), () {
      widget.onSave(newAssignment);
      setState(() {
        _isLoading = false;
      });
      widget.onClose();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Assign To User',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      GestureDetector(
                        onTap: widget.onClose,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            color: Colors.grey[600],
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  TextFormField(
                    controller: _staffNameController,
                    decoration: InputDecoration(
                      hintText: 'Staff Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the staff name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _locationController,
                    decoration: InputDecoration(
                      hintText: 'Location',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the location';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _assignedFromController,
                    decoration: InputDecoration(
                      hintText: 'Assigned From',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter who this is assigned from';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _adminController,
                    decoration: InputDecoration(
                      hintText: 'Admin',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the admin\'s name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  // Return Date and Time
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _presentDatePicker,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.grey[50],
                            ),
                            child: Text(
                              _returnDate == null
                                  ? 'Select Return Date'
                                  : '${_returnDate!.day}/${_returnDate!.month}/${_returnDate!.year}',
                              style: TextStyle(
                                fontSize: 16,
                                color: _returnDate == null
                                    ? Colors.grey[400]
                                    : Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GestureDetector(
                          onTap: _presentTimePicker,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.grey[50],
                            ),
                            child: Text(
                              _returnTime == null
                                  ? 'Select Return Time'
                                  : _returnTime!.format(context),
                              style: TextStyle(
                                fontSize: 16,
                                color: _returnTime == null
                                    ? Colors.grey[400]
                                    : Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: _isLoading ? null : AppTheme.primaryGradient,
                        color: _isLoading ? Colors.grey[400] : null,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: _isLoading ? null : [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveAssignment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Save Assignment',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// New widget to handle the mobile scanner view.
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
      body: MobileScanner(
        controller: MobileScannerController(
          detectionSpeed: DetectionSpeed.normal,
        ),
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
            final String qrCode = barcodes.first.rawValue!;
            widget.onScan(qrCode);
            Navigator.of(context).pop();
          }
        },
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
  bool collectionsExpanded = false;
  bool issuesExpanded = false;
  bool remindersExpanded = false;
  bool informationExpanded = false;
  bool commentsExpanded = false;
  bool attachmentsExpanded = false;
  bool tagsExpanded = false;
  bool historyExpanded = false;

  final _collectionsController = TextEditingController();
  final _issuesController = TextEditingController();
  final _remindersController = TextEditingController();
  final _informationTitleController = TextEditingController();
  final _informationBodyController = TextEditingController();
  final _commentController = TextEditingController();

  final _reminderNameController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _selectedRepeatOption = 'Never';
  final List<String> _repeatOptions = [
    'Never',
    'Daily',
    'Weekly',
    'Bi-weekly',
    'Monthly',
  ];

  String? _taggedQrCode;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _taggedQrCode = widget.item.qrCodeId;
    // Add initial history entry
    ItemDetailsService.addHistoryEntry(
      widget.item.id,
      HistoryEntry(
        title: 'Item Details Viewed',
        description: 'You are now viewing this item\'s details.',
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _collectionsController.dispose();
    _issuesController.dispose();
    _remindersController.dispose();
    _informationTitleController.dispose();
    _informationBodyController.dispose();
    _reminderNameController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _addHistoryEntry(
      {required String title,
      required String description,
      IconData? icon}) async {
    await ItemDetailsService.addHistoryEntry(
      widget.item.id,
      HistoryEntry(
        title: title,
        description: description,
        timestamp: DateTime.now(),
        icon: icon,
      ),
    );
  }

  void _saveInformation(String section) {
    switch (section) {
      case 'Collections':
        final data = _collectionsController.text;
        _addHistoryEntry(
          title: 'Collection Added',
          description: 'Added "$data" to collections.',
          icon: Icons.folder_open,
        );
        break;
      case 'Issues':
        break;
      case 'Reminders':
        final name = _reminderNameController.text;
        final date = _selectedDate;
        final time = _selectedTime;
        final repeat = _selectedRepeatOption;

        // Save reminder logic would go here
        _addHistoryEntry(
          title: 'Reminder Saved',
          description: 'Set a reminder for "$name" to repeat $repeat.',
          icon: Icons.access_time,
        );
        break;
      case 'Information':
        _saveInformationEntry();
        break;
      default:
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$section saved successfully!')),
    );
  }

  Future<void> _saveInformationEntry() async {
    final title = _informationTitleController.text.trim();
    final body = _informationBodyController.text.trim();

    if (title.isNotEmpty || body.isNotEmpty) {
      final newInformation = Information(
        id: '',
        title: title.isEmpty ? 'Untitled' : title,
        body: body,
        timestamp: DateTime.now(),
      );

      try {
        await ItemDetailsService.addInformation(widget.item.id, newInformation);
        await _addHistoryEntry(
          title: 'Information Updated',
          description:
              'Added a new information entry: "${newInformation.title}"',
          icon: Icons.info_outline,
        );
        _informationTitleController.clear();
        _informationBodyController.clear();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Information saved successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save information: ${e.toString()}'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Please enter a title or body for the information.')),
        );
      }
    }
  }

  Future<void> _saveComment() async {
    if (_commentController.text.isNotEmpty) {
      final user = FirebaseService.currentUser;
      final newComment = Comment(
        id: '',
        text: _commentController.text,
        author: user?.email?.split('@').first ?? 'User',
        timestamp: DateTime.now(),
      );

      try {
        await ItemDetailsService.addComment(widget.item.id, newComment);
        await _addHistoryEntry(
          title: 'New Comment Added',
          description: 'Added a new comment: "${_commentController.text}"',
          icon: Icons.comment,
        );
        _commentController.clear();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Comment saved successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save comment: ${e.toString()}'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  void _pickAttachment() async {
    // Show source selection
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: SafeArea(
            child: Wrap(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.photo_library, color: Colors.blue),
                  title: const Text('Choose from Gallery'),
                  onTap: () => Navigator.of(context).pop(ImageSource.gallery),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_camera, color: Colors.green),
                  title: const Text('Take a Photo'),
                  onTap: () => Navigator.of(context).pop(ImageSource.camera),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (source == null) return;

    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      final file = File(image.path);
      final timestamp = DateTime.now();

      // Create attachment and save to Firestore first
      final newAttachment = Attachment(
        id: '',
        name: 'Attachment ${timestamp.millisecondsSinceEpoch}',
        timestamp: timestamp,
      );

      try {
        final attachmentId = await ItemDetailsService.addAttachment(
          widget.item.id,
          newAttachment,
        );

        // Upload to Firebase Storage in background
        _uploadAttachment(attachmentId, file, newAttachment.name);

        await _addHistoryEntry(
          title: 'New Attachment Added',
          description: 'Added a new attachment.',
          icon: Icons.attachment,
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save attachment: ${e.toString()}'),
              backgroundColor: AppTheme.errorColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  /// Download QR code as image
  Future<void> _downloadQrCode(String barcode) async {
    try {
      // Create QR code painter
      final painter = QrPainter(
        data: barcode,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.L,
        color: Colors.black,
        emptyColor: Colors.white,
      );

      // Render to image
      final picRecorder = ui.PictureRecorder();
      final canvas = Canvas(picRecorder);
      const size = 300.0;
      painter.paint(canvas, Size(size, size));
      final picture = picRecorder.endRecording();
      final image = await picture.toImage(size.toInt(), size.toInt());
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      // Save to file
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'QR_${widget.item.name.replaceAll(' ', '_')}_$barcode.png';
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(pngBytes);

      // Share the file
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'QR Code for ${widget.item.name}',
        subject: 'Item QR Code: $barcode',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('QR code saved and ready to share'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download QR code: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _uploadAttachment(
      String attachmentId, File file, String name) async {
    try {
      final url = await StorageService.uploadAttachment(
        file: file,
        itemId: widget.item.id,
        fileName: name,
      );

      // Update attachment with URL in Firestore
      await ItemDetailsService.updateAttachment(
        widget.item.id,
        attachmentId,
        url,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload attachment: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleTagging() async {
    // Navigate to a new screen with the scanner
    Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => QRScannerPage(onScan: (qrCode) {
              final updatedItem = widget.item.copyWith(
                qrCodeId: qrCode,
                isTagged: true,
              );
              widget.onUpdateItem(updatedItem);

              setState(() {
                _taggedQrCode = qrCode;
              });

              _addHistoryEntry(
                title: 'Item Tagged',
                description: 'Item was tagged with QR code: $qrCode',
                icon: Icons.qr_code,
              );
            })));
  }

  Future<void> _presentDatePicker() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Future<void> _presentTimePicker() async {
    final now = TimeOfDay.now();
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? now,
    );
    if (pickedTime != null) {
      setState(() {
        _selectedTime = pickedTime;
      });
    }
  }

  // FIXED: Added the missing _handleAssignToUser method.
  void _handleAssignToUser() {
    _addHistoryEntry(
      title: 'Assign Form Opened',
      description: 'The assign to user form was opened.',
      icon: Icons.person_add_alt_1,
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (_, controller) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: AssignToUserWidget(
                onSave: (assignment) async {
                  // Save assignment as a checkout
                  try {
                    await ItemDetailsService.addCheckout(
                      itemId: widget.item.id,
                      assignedFrom: assignment.assignedFrom,
                      assignedTo: assignment.staffName,
                      admin: assignment.admin,
                      returnDate: assignment.returnDate,
                    );
                    await _addHistoryEntry(
                      title: 'Item Assigned',
                      description:
                          'Assigned to ${assignment.staffName} at ${assignment.location} by ${assignment.admin}. Return date: ${assignment.returnDate.day}/${assignment.returnDate.month}/${assignment.returnDate.year}.',
                      icon: Icons.assignment_ind,
                    );
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Failed to save assignment: ${e.toString()}'),
                          backgroundColor: AppTheme.errorColor,
                        ),
                      );
                    }
                  }
                },
                onClose: () {
                  Navigator.of(context).pop();
                },
              ),
            );
          },
        );
      },
    );
  }

  void _handleCheckout() {
    _addHistoryEntry(
      title: 'Checkout Form Opened',
      description: 'The checkout form for this item was opened.',
      icon: Icons.shopping_cart,
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return CheckoutWidget(
          itemId: widget.item.id,
          onSave: () async {
            await _addHistoryEntry(
              title: 'Item Checked Out',
              description: 'The item was successfully checked out to a user.',
              icon: Icons.check,
            );
          },
          onClose: () {
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  void _handleRaiseIssue() {
    _addHistoryEntry(
      title: 'Raise Issue Form Opened',
      description: 'The raise issue form for this item was opened.',
      icon: Icons.report_problem_outlined,
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return RaiseIssueWidget(
          onSave: (newIssue) async {
            try {
              await ItemDetailsService.addIssue(widget.item.id, newIssue);
              await _addHistoryEntry(
                title: 'New Issue Reported',
                description:
                    'Priority: ${newIssue.priority} - ${newIssue.description}',
                icon: Icons.warning_amber,
              );
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to save issue: ${e.toString()}'),
                    backgroundColor: AppTheme.errorColor,
                  ),
                );
              }
            }
          },
          onClose: () {
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ItemHeader(
              item: widget.item,
            ),
            const SizedBox(height: 24),
            // Assign To User Button - Made more prominent
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _handleAssignToUser,
                icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
                label: const Text(
                  'Assign To User',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ActionButton(
                    icon: Icons.shopping_cart_checkout_outlined,
                    text: 'Checkout',
                    onPressed: _handleCheckout,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ActionButton(
                    icon: Icons.report_problem_outlined,
                    text: 'Raise Issue',
                    onPressed: _handleRaiseIssue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildExpandableSection(
              title: 'Collections',
              subtitle: 'Categorize and organize the things that matter to you',
              isExpanded: collectionsExpanded,
              onTap: () =>
                  setState(() => collectionsExpanded = !collectionsExpanded),
              hasSaveButton: true,
              expandedContent: TextFormField(
                controller: _collectionsController,
                decoration: InputDecoration(
                  hintText: 'Add a new collection',
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
            ExpandableSection(
              title: 'Issues',
              subtitle: 'Report and manage issues for this item here',
              isExpanded: issuesExpanded,
              onTap: () => setState(() => issuesExpanded = !issuesExpanded),
              hasSaveButton: false,
              expandedContent: IssuesSection(
                itemId: widget.item.id,
                onRaiseIssue: _handleRaiseIssue,
              ),
            ),
            _buildExpandableSection(
              title: 'Reminders',
              subtitle: 'Remember everything with notifications',
              isExpanded: remindersExpanded,
              onTap: () =>
                  setState(() => remindersExpanded = !remindersExpanded),
              hasSaveButton: true,
              expandedContent: Column(
                children: [
                  TextFormField(
                    controller: _reminderNameController,
                    decoration: InputDecoration(
                      hintText: 'Reminder Name',
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _presentDatePicker,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today,
                                    size: 20, color: Colors.blue),
                                const SizedBox(width: 8),
                                Text(
                                  _selectedDate == null
                                      ? 'Select Date'
                                      : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                                  style: const TextStyle(
                                      fontSize: 16, color: Colors.black87),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GestureDetector(
                          onTap: _presentTimePicker,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time,
                                    size: 20, color: Colors.blue),
                                const SizedBox(width: 8),
                                Text(
                                  _selectedTime == null
                                      ? 'Select Time'
                                      : _selectedTime!.format(context),
                                  style: const TextStyle(
                                      fontSize: 16, color: Colors.black87),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                      ),
                      initialValue: _selectedRepeatOption,
                      items: _repeatOptions.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedRepeatOption = newValue!;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            ExpandableSection(
              title: 'Information',
              subtitle: 'Keep all important information in one handy place',
              isExpanded: informationExpanded,
              onTap: () =>
                  setState(() => informationExpanded = !informationExpanded),
              hasSaveButton: true,
              onSave: () => _saveInformation('Information'),
              expandedContent: InformationSection(
                itemId: widget.item.id,
                titleController: _informationTitleController,
                bodyController: _informationBodyController,
              ),
            ),
            ExpandableSection(
              title: 'Comments',
              subtitle: 'Add and view comments on this item',
              isExpanded: commentsExpanded,
              onTap: () => setState(() => commentsExpanded = !commentsExpanded),
              hasSaveButton: false,
              expandedContent: CommentsSection(
                itemId: widget.item.id,
                commentController: _commentController,
                onSaveComment: _saveComment,
              ),
            ),
            ExpandableSection(
              title: 'Tags',
              subtitle: 'Tag your assets to easily identify',
              isExpanded: tagsExpanded,
              onTap: () => setState(() => tagsExpanded = !tagsExpanded),
              hasSaveButton: false,
              expandedContent: QrCodeSection(
                qrCode: _taggedQrCode,
                isTagged: widget.item.isTagged,
                onTag: _handleTagging,
                onDownload: () => _downloadQrCode(_taggedQrCode!),
              ),
            ),
            ExpandableSection(
              title: 'Attachments',
              subtitle: 'Add photos and documents to your item',
              isExpanded: attachmentsExpanded,
              onTap: () =>
                  setState(() => attachmentsExpanded = !attachmentsExpanded),
              hasSaveButton: false,
              expandedContent: AttachmentsSection(
                itemId: widget.item.id,
                onAddAttachment: _pickAttachment,
              ),
            ),
            _buildExpandableSection(
              title: 'History',
              subtitle: 'Tag your assets to easily identify',
              isExpanded: historyExpanded,
              onTap: () {
                if (!historyExpanded) {
                  // Navigate to history screen with stream
                  Navigator.of(context).push(MaterialPageRoute(
                    fullscreenDialog: true,
                    builder: (context) => StreamBuilder<List<HistoryEntry>>(
                      stream:
                          ItemDetailsService.getHistoryStream(widget.item.id),
                      builder: (context, snapshot) {
                        final historyItems = snapshot.data ?? [];
                        return HistoryScreen(history: historyItems);
                      },
                    ),
                  ));
                }
                setState(() => historyExpanded = !historyExpanded);
              },
              hasSaveButton: false,
              expandedContent: StreamBuilder<List<HistoryEntry>>(
                stream: ItemDetailsService.getHistoryStream(widget.item.id),
                builder: (context, snapshot) {
                  final historyItems = snapshot.data ?? [];
                  return Column(
                    children: historyItems.reversed
                        .map((entry) => HistoryEntryCard(entry: entry))
                        .toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandableSection({
    required String title,
    required String subtitle,
    required bool isExpanded,
    required VoidCallback onTap,
    Widget? expandedContent,
    bool hasSaveButton = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      isExpanded ? Icons.remove : Icons.add,
                      color: Colors.black87,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isExpanded)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  expandedContent ??
                      Text(
                        'Content for $title section would go here.',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                  if (hasSaveButton) ...[
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () => _saveInformation(title),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Save',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
