import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:math';
import 'package:flutter_application_1/widgets/issue_model.dart';

// This widget is a form for users to raise an issue for an item.
// It is designed to be shown as a modal bottom sheet.
class RaiseIssueWidget extends StatefulWidget {
  // A callback function to pass the saved data back to the parent widget.
  final Function(Issue)? onSave;
  // A callback function to close the modal.
  final VoidCallback? onClose;

  const RaiseIssueWidget({
    Key? key,
    this.onSave,
    this.onClose,
  }) : super(key: key);

  @override
  State<RaiseIssueWidget> createState() => _RaiseIssueWidgetState();
}

class _RaiseIssueWidgetState extends State<RaiseIssueWidget> {
  // GlobalKey for form validation.
  final _formKey = GlobalKey<FormState>();
  // Controller for the issue description text field.
  final _descriptionController = TextEditingController();

  // State variables for the form.
  String _selectedPriority = 'None';
  final List<String> _priorityOptions = [
    'None',
    'Low',
    'Medium',
    'High',
    'Critical',
  ];
  File? _selectedAttachment;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  // This function handles picking an image for the optional attachment.
  Future<void> _pickAttachment() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _selectedAttachment = File(image.path);
      });
    }
  }

  // Function to simulate saving the issue report.
  void _saveIssue() {
    // Validate the form.
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Create a unique issue ID.
    final newIssueId = Random().nextInt(99999999).toString();

    // Create the new Issue object.
    final newIssue = Issue(
      issueId: newIssueId,
      description: _descriptionController.text.trim(),
      priority: _selectedPriority,
      attachment: _selectedAttachment,
      createdAt: DateTime.now(),
    );

    // Placeholder logic for saving.
    print('Saving Issue Report:');
    print('  ID: ${newIssue.issueId}');
    print('  Description: ${newIssue.description}');
    print('  Priority: ${newIssue.priority}');
    print('  Attachment: ${newIssue.attachment != null ? 'Yes' : 'No'}');
    print('  Reporter: ${newIssue.reporter}');

    // Simulate save delay.
    Future.delayed(const Duration(milliseconds: 500), () {
      if (widget.onSave != null) {
        widget.onSave!(newIssue);
      }
      setState(() {
        _isLoading = false;
      });
      if (widget.onClose != null) {
        widget.onClose!();
      }
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
                  // Header with title and close button.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Raise Issue',
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

                  // Description box
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: 'Describe the issue...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
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
                        return 'Please provide a description of the issue.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Priority dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                      ),
                      value: _selectedPriority,
                      items: _priorityOptions.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedPriority = newValue!;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Optional attachment
                  GestureDetector(
                    onTap: _pickAttachment,
                    child: Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.grey[300]!,
                          width: 2,
                          style: BorderStyle.solid,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _selectedAttachment != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.file(
                                    _selectedAttachment!,
                                    fit: BoxFit.cover,
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedAttachment = null;
                                        });
                                      },
                                      child: Container(
                                        width: 32,
                                        height: 32,
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.camera_alt_outlined,
                                    size: 32,
                                    color: Colors.grey[500],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Take a photo of the issue',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tap to add photo',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveIssue,
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
                              'Save Issue',
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
