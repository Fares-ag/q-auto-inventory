// lib/widgets/raise_issue.dart

import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/issue_model.dart';
import 'package:flutter_application_1/services/local_data_store.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class RaiseIssueWidget extends StatefulWidget {
  final String itemId;
  final VoidCallback? onClose;

  const RaiseIssueWidget({Key? key, required this.itemId, this.onClose})
      : super(key: key);

  @override
  State<RaiseIssueWidget> createState() => _RaiseIssueWidgetState();
}

class _RaiseIssueWidgetState extends State<RaiseIssueWidget> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();

  IssuePriority _selectedPriority = IssuePriority.Medium;
  File? _selectedAttachment;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickAttachment() async {
    final XFile? image =
        await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (image != null) {
      setState(() {
        _selectedAttachment = File(image.path);
      });
    }
  }

  void _saveIssue() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final issueId = 'issue_${DateTime.now().millisecondsSinceEpoch}';

      final newIssue = Issue(
        issueId: issueId,
        itemId: widget.itemId,
        description: _descriptionController.text.trim(),
        priority: _selectedPriority,
        reporterId: 'dummy_user_id',
        attachmentUrl: _selectedAttachment?.path,
        createdAt: DateTime.now(),
      );

      LocalDataStore().raiseIssue(newIssue);

      if (mounted) {
        if (widget.onClose != null) widget.onClose!();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Failed to save issue: $e'),
            backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Raise Issue',
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black)),
                    IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: widget.onClose),
                  ],
                ),
                const SizedBox(height: 30),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Describe the issue...',
                    fillColor: Colors.grey[50],
                    filled: true,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? 'Please provide a description.' : null,
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<IssuePriority>(
                  value: _selectedPriority,
                  decoration: InputDecoration(
                    labelText: 'Priority',
                    fillColor: Colors.grey[50],
                    filled: true,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                  items: IssuePriority.values.map((priority) {
                    return DropdownMenuItem<IssuePriority>(
                        value: priority, child: Text(priority.name));
                  }).toList(),
                  onChanged: (newValue) {
                    if (newValue != null) {
                      setState(() => _selectedPriority = newValue);
                    }
                  },
                ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: _pickAttachment,
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Add Attachment'),
                ),
                if (_selectedAttachment != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Image.file(_selectedAttachment!, height: 100),
                  ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isLoading ? null : _saveIssue,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Submit Issue',
                            style:
                                TextStyle(fontSize: 18, color: Colors.white)),
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
