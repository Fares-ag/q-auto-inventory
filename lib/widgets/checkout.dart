import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_application_1/services/item_details_service.dart';
import 'package:flutter_application_1/services/storage_service.dart';
import 'package:flutter_application_1/config/app_theme.dart';
import 'dart:io';

// A widget for the checkout form, designed to be shown as a modal.
class CheckoutWidget extends StatefulWidget {
  final String itemId;
  final VoidCallback? onSave;
  final VoidCallback? onClose;

  const CheckoutWidget({
    Key? key,
    required this.itemId,
    this.onSave,
    this.onClose,
  }) : super(key: key);

  @override
  State<CheckoutWidget> createState() => _CheckoutWidgetState();
}

class _CheckoutWidgetState extends State<CheckoutWidget> {
  // GlobalKey for form validation.
  final _formKey = GlobalKey<FormState>();
  // Controllers for the form text fields.
  final _assignFromController = TextEditingController();
  final _assignToController = TextEditingController();
  final _adminController = TextEditingController();

  // State variables for the form.
  DateTime? _returnDate;
  TimeOfDay? _returnTime;
  File? _selectedAttachment;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void dispose() {
    _assignFromController.dispose();
    _assignToController.dispose();
    _adminController.dispose();
    super.dispose();
  }

  // A helper function to show the date picker.
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

  // A helper function to show the time picker.
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

  // Function to save checkout information to Firestore.
  Future<void> _saveCheckout() async {
    // Validate the form.
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

    try {
      // Combine date and time
      final returnDateTime = DateTime(
        _returnDate!.year,
        _returnDate!.month,
        _returnDate!.day,
        _returnTime!.hour,
        _returnTime!.minute,
      );

      // Upload attachment if provided
      String? attachmentUrl;
      if (_selectedAttachment != null) {
        try {
          attachmentUrl = await StorageService.uploadAttachment(
            file: _selectedAttachment!,
            itemId: widget.itemId,
            fileName: 'checkout_${DateTime.now().millisecondsSinceEpoch}.jpg',
          );
        } catch (e) {
          // Continue even if image upload fails
          debugPrint('Failed to upload checkout image: $e');
        }
      }

      // Save checkout to Firestore
      await ItemDetailsService.addCheckout(
        itemId: widget.itemId,
        assignedFrom: _assignFromController.text.trim(),
        assignedTo: _assignToController.text.trim(),
        admin: _adminController.text.trim(),
        returnDate: returnDateTime,
        attachmentUrl: attachmentUrl,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Checkout saved successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }

      if (widget.onSave != null) {
        widget.onSave!();
      }

      if (mounted && widget.onClose != null) {
        widget.onClose!();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save checkout: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // This function is for picking a photo from the gallery or camera.
  Future<void> _pickAttachment() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _selectedAttachment = File(image.path);
      });
    }
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
                        'Checkout',
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

                  // Assigned From
                  TextFormField(
                    controller: _assignFromController,
                    decoration: InputDecoration(
                      hintText: 'Assigned From',
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
                        return 'Please enter who this is assigned from';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Assigned To
                  TextFormField(
                    controller: _assignToController,
                    decoration: InputDecoration(
                      hintText: 'Assigned To',
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
                        return 'Please enter who this is assigned to';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Admin
                  TextFormField(
                    controller: _adminController,
                    decoration: InputDecoration(
                      hintText: 'Admin',
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
                  const SizedBox(height: 20),

                  // Item Attachment
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
                                  'Take a photo of your item',
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
                      onPressed: _isLoading ? null : _saveCheckout,
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
                              'Save Checkout',
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
