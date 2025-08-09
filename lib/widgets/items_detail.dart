import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/item_model.dart';
import 'package:flutter_application_1/widgets/history_screen.dart';
import 'package:flutter_application_1/widgets/checkout.dart';
import 'package:flutter_application_1/widgets/raise_issue.dart';
import 'package:flutter_application_1/widgets/issue_model.dart';
import 'package:flutter_application_1/widgets/history_entry_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'dart:io';
import 'dart:math';

// Data model for a single comment.
class Comment {
  final String text;
  final String author;
  final DateTime timestamp;

  Comment({
    required this.text,
    required this.author,
    required this.timestamp,
  });
}

// Data model for a single attachment.
class Attachment {
  final String name;
  final File file;
  final DateTime timestamp;

  Attachment({
    required this.name,
    required this.file,
    required this.timestamp,
  });
}

// Data model for a single information entry.
class Information {
  final String title;
  final String body;
  final DateTime timestamp;

  Information({
    required this.title,
    required this.body,
    required this.timestamp,
  });
}

// Data model for an assignment.
class Assignment {
  final String staffName;
  final String location;
  final DateTime timestamp;

  Assignment({
    required this.staffName,
    required this.location,
    required this.timestamp,
  });
}

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
  bool _isLoading = false;

  @override
  void dispose() {
    _staffNameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _saveAssignment() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final newAssignment = Assignment(
      staffName: _staffNameController.text.trim(),
      location: _locationController.text.trim(),
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
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveAssignment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor: Colors.grey[400],
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
                ],
              ),
            ),
          ),
        ),
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

  List<Issue> reportedIssues = [];
  List<Comment> comments = [];
  List<Attachment> attachments = [];
  List<Information> informationEntries = [];
  final List<HistoryEntry> _historyItems = [];

  // State variable to hold the scanned QR code ID
  String? _taggedQrCode;

  // Create an instance of ImagePicker
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Initialize the tagged QR code from the item data
    _taggedQrCode = widget.item.qrCodeId;
    _addHistoryEntry(
      title: 'Item Details Viewed',
      description: 'You are now viewing this item\'s details.',
      icon: Icons.visibility,
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

  void _addHistoryEntry(
      {required String title, required String description, IconData? icon}) {
    setState(() {
      _historyItems.add(
        HistoryEntry(
          title: title,
          description: description,
          timestamp: DateTime.now(),
          icon: icon,
        ),
      );
    });
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
        // The issue save logic is now in _handleRaiseIssue
        break;
      case 'Reminders':
        final name = _reminderNameController.text;
        final date = _selectedDate;
        final time = _selectedTime;
        final repeat = _selectedRepeatOption;

        // This is where you would save the reminder to a database or state
        print(
            'Saving Reminder: Name: $name, Date: $date, Time: $time, Repeat: $repeat');
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
      // No action needed for other sections
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$section saved successfully!')),
    );
  }

  // New handler for saving information entries.
  void _saveInformationEntry() {
    final title = _informationTitleController.text.trim();
    final body = _informationBodyController.text.trim();

    if (title.isNotEmpty || body.isNotEmpty) {
      final newInformation = Information(
        title: title.isEmpty ? 'Untitled' : title,
        body: body,
        timestamp: DateTime.now(),
      );
      setState(() {
        informationEntries.add(newInformation);
      });
      _addHistoryEntry(
        title: 'Information Updated',
        description: 'Added a new information entry: "${newInformation.title}"',
        icon: Icons.info_outline,
      );
      _informationTitleController.clear();
      _informationBodyController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Information saved successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter a title or body for the information.')),
      );
    }
  }

  void _saveComment() {
    if (_commentController.text.isNotEmpty) {
      final newComment = Comment(
        text: _commentController.text,
        author: 'Charlotte',
        timestamp: DateTime.now(),
      );
      setState(() {
        comments.add(newComment);
      });
      _addHistoryEntry(
        title: 'New Comment Added',
        description: 'Added a new comment: "${_commentController.text}"',
        icon: Icons.comment,
      );
      _commentController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comment saved successfully!')),
      );
    }
  }

  void _pickAttachment() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      final newAttachment = Attachment(
        name: 'Attachment ${attachments.length + 1}',
        file: File(image.path),
        timestamp: DateTime.now(),
      );
      setState(() {
        attachments.add(newAttachment);
      });
      _addHistoryEntry(
        title: 'New Attachment Added',
        description: 'Added a new attachment via camera.',
        icon: Icons.attachment,
      );
    }
  }

  // New method to handle QR tagging
  Future<void> _handleTagging() async {
    String barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
        "#ff6666", "Cancel", true, ScanMode.QR);

    if (barcodeScanRes != '-1' && barcodeScanRes.isNotEmpty) {
      // Create a new item with the updated qrCodeId
      final updatedItem = widget.item.copyWith(
        qrCodeId: barcodeScanRes,
        isTagged: true,
      );

      // Call the callback to update the item in the parent list
      widget.onUpdateItem(updatedItem);

      setState(() {
        _taggedQrCode = barcodeScanRes;
      });

      _addHistoryEntry(
        title: 'Item Tagged',
        description: 'Item was tagged with QR code: $barcodeScanRes',
        icon: Icons.qr_code,
      );
    }
  }

  // New method to handle the "Assign to User" pop-up.
  void _handleAssignToUser() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return AssignToUserWidget(
          onSave: (newAssignment) {
            _addHistoryEntry(
              title: 'Item Assigned',
              description:
                  'Assigned to ${newAssignment.staffName} at ${newAssignment.location}.',
              icon: Icons.person,
            );
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Item assigned successfully!')),
            );
          },
          onClose: () {
            Navigator.of(context).pop();
          },
        );
      },
    );
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
          onSave: () {
            print('Checkout process completed for item: ${widget.item.name}');
            _addHistoryEntry(
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
          onSave: (newIssue) {
            setState(() {
              reportedIssues.add(newIssue);
            });
            _addHistoryEntry(
              title: 'New Issue Reported',
              description:
                  'Priority: ${newIssue.priority} - ${newIssue.description}',
              icon: Icons.warning_amber,
            );
            print('Issue reported for item: ${widget.item.name}');
            print('Current issues: ${reportedIssues.length}');
          },
          onClose: () {
            Navigator.of(context).pop();
            // Optionally, you can add this to the item's history or issues list
          },
        );
      },
    );
  }

  Widget _buildIssueCard(Issue issue) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Priority: ${issue.priority}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Status: ${issue.status}',
                style: TextStyle(
                  color: Colors.green[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(issue.description),
          const SizedBox(height: 8),
          Text(
            'Issue ID: ${issue.issueId}',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 4),
          Text(
            'Reporter: ${issue.reporter}',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildInformationCard(Information info) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            info.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          if (info.body.isNotEmpty)
            Text(
              info.body,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          const SizedBox(height: 8),
          Text(
            'Saved on ${info.timestamp.day}/${info.timestamp.month}/${info.timestamp.year} at ${info.timestamp.hour}:${info.timestamp.minute}',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryEntryCard(HistoryEntry entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (entry.icon != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(entry.icon, size: 24, color: Colors.blue),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  entry.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${entry.timestamp.day}/${entry.timestamp.month}/${entry.timestamp.year} at ${entry.timestamp.hour}:${entry.timestamp.minute}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentCard(Comment comment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            comment.text,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'By ${comment.author} on ${comment.timestamp.day}/${comment.timestamp.month}/${comment.timestamp.year} at ${comment.timestamp.hour}:${comment.timestamp.minute}',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentCard(Attachment attachment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.insert_photo_outlined, color: Colors.grey, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Added on ${attachment.timestamp.day}/${attachment.timestamp.month}/${attachment.timestamp.year}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.download, color: Colors.blue),
            onPressed: () {
              // Add download logic here.
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[300],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Center(child: buildItemIcon(widget.item.itemType)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.item.category,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.item.name,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '#${widget.item.id}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // New GestureDetector for "Assign to User"
            GestureDetector(
              onTap: _handleAssignToUser,
              child: Row(
                children: [
                  Icon(Icons.person_outline, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Assign To User',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.shopping_cart_checkout_outlined,
                    text: 'Checkout',
                    onPressed: _handleCheckout,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
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
            _buildExpandableSection(
              title: 'Issues',
              subtitle: 'Report and manage issues for this item here',
              isExpanded: issuesExpanded,
              onTap: () => setState(() => issuesExpanded = !issuesExpanded),
              hasSaveButton: false,
              expandedContent: Column(
                children: [
                  ...reportedIssues
                      .map((issue) => _buildIssueCard(issue))
                      .toList(),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _handleRaiseIssue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Add New Issue'),
                    ),
                  ),
                ],
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
                      value: _selectedRepeatOption,
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
            _buildExpandableSection(
              title: 'Information',
              subtitle: 'Keep all important information in one handy place',
              isExpanded: informationExpanded,
              onTap: () =>
                  setState(() => informationExpanded = !informationExpanded),
              hasSaveButton: true,
              expandedContent: Column(
                children: [
                  // Display existing information entries
                  ...informationEntries.reversed
                      .map((info) => _buildInformationCard(info))
                      .toList(),
                  if (informationEntries.isNotEmpty) const SizedBox(height: 16),

                  // New input fields for adding a new entry
                  TextFormField(
                    controller: _informationTitleController,
                    decoration: InputDecoration(
                      hintText: 'Information Title',
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
                  TextFormField(
                    controller: _informationBodyController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: 'Enter additional information...',
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
                ],
              ),
            ),
            _buildExpandableSection(
              title: 'Comments',
              subtitle: 'Add and view comments on this item',
              isExpanded: commentsExpanded,
              onTap: () => setState(() => commentsExpanded = !commentsExpanded),
              hasSaveButton: false,
              expandedContent: Column(
                children: [
                  ...comments.reversed
                      .map((comment) => _buildCommentCard(comment))
                      .toList(),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _commentController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Write a new comment...',
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
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveComment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Add Comment'),
                    ),
                  ),
                ],
              ),
            ),
            _buildExpandableSection(
              title: 'Tags',
              subtitle: 'Tag your assets to easily identify',
              isExpanded: tagsExpanded,
              onTap: () => setState(() => tagsExpanded = !tagsExpanded),
              hasSaveButton: false,
              expandedContent: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_taggedQrCode != null)
                    Text(
                      'Tagged with QR Code: $_taggedQrCode',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[800],
                      ),
                    )
                  else
                    const Text(
                      'This item is not yet tagged.',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.red,
                      ),
                    ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: widget.item.isTagged ? null : _handleTagging,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(widget.item.isTagged
                          ? 'Already Tagged'
                          : 'Scan to Tag'),
                    ),
                  ),
                ],
              ),
            ),
            _buildExpandableSection(
              title: 'Attachments',
              subtitle: 'Add photos and documents to your item',
              isExpanded: attachmentsExpanded,
              onTap: () =>
                  setState(() => attachmentsExpanded = !attachmentsExpanded),
              hasSaveButton: false,
              expandedContent: Column(
                children: [
                  ...attachments
                      .map((attachment) => _buildAttachmentCard(attachment))
                      .toList(),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _pickAttachment,
                      child: const Text('Add Attachment'),
                    ),
                  ),
                ],
              ),
            ),
            _buildExpandableSection(
              title: 'History',
              subtitle: 'Tag your assets to easily identify',
              isExpanded: historyExpanded,
              onTap: () {
                if (!historyExpanded) {
                  Navigator.of(context).push(MaterialPageRoute(
                    fullscreenDialog: true,
                    builder: (context) => HistoryScreen(history: _historyItems),
                  ));
                }
                setState(() => historyExpanded = !historyExpanded);
              },
              hasSaveButton: false,
              expandedContent: Column(
                children: _historyItems.reversed
                    .map((entry) => _buildHistoryEntryCard(entry))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String text,
    required VoidCallback onPressed,
  }) {
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
              Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
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
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
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
                    ElevatedButton(
                      onPressed: () => _saveInformation(title),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
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
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildItemIcon(ItemType type) {
    switch (type) {
      case ItemType.laptop:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 35,
              height: 22,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 2),
            Container(
              width: 40,
              height: 3,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        );
      case ItemType.keyboard:
        return Container(
          width: 35,
          height: 25,
          decoration: BoxDecoration(
            color: Colors.grey[700],
            borderRadius: BorderRadius.circular(4),
          ),
          child: GridView.builder(
            padding: const EdgeInsets.all(4),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 1,
              crossAxisSpacing: 1,
              mainAxisSpacing: 1,
            ),
            itemCount: 12,
            itemBuilder: (context, index) => Container(
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        );
      case ItemType.furniture:
        return const Icon(Icons.chair, size: 40, color: Colors.brown);
      case ItemType.monitor:
        return const Icon(Icons.monitor, size: 40, color: Colors.black);
      case ItemType.tablet:
        return const Icon(Icons.tablet_android,
            size: 40, color: Colors.blueGrey);
      case ItemType.webcam:
        return const Icon(Icons.videocam, size: 40, color: Colors.grey);
      default:
        return Icon(Icons.inventory, color: Colors.grey[600]);
    }
  }
}
