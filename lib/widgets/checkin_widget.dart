// lib/widgets/checkin_widget.dart

import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_signature_pad/flutter_signature_pad.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

// Enum to represent item condition states
enum ItemCondition { Excellent, Good, Fair, Poor }

class CheckinWidget extends StatefulWidget {
  // Callback for closing the widget
  final VoidCallback onClose;

  // Callback for saving check-in data
  final Function({
    required bool isWriteOff,
    required ItemCondition condition,
    required String? assignedStaff,
    required File? attachment,
    required ByteData? staffSignature,
    required ByteData? operatorSignature,
  }) onSave;

  // Optional: name of staff to whom the item was assigned
  final String? assignedStaff;

  const CheckinWidget({
    Key? key,
    required this.onClose,
    required this.onSave,
    this.assignedStaff,
  }) : super(key: key);

  @override
  State<CheckinWidget> createState() => _CheckinWidgetState();
}

class _CheckinWidgetState extends State<CheckinWidget> {
  // Default selected condition
  ItemCondition _selectedCondition = ItemCondition.Good;

  bool _isLoading = false; // Prevents multiple saves while processing
  File? _selectedAttachment; // Stores attached photo (optional)

  final ImagePicker _picker = ImagePicker();

  // Keys for capturing signatures
  final GlobalKey<SignatureState> _staffSignatureKey =
      GlobalKey<SignatureState>();
  final GlobalKey<SignatureState> _operatorSignatureKey =
      GlobalKey<SignatureState>();

  // Opens camera and sets image as attachment
  Future<void> _pickAttachment() async {
    final XFile? image =
        await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (image != null) {
      setState(() {
        _selectedAttachment = File(image.path);
      });
    }
  }

  // Handles save (both normal check-in and write-off)
  void _handleSave(bool isWriteOff) async {
    setState(() => _isLoading = true);

    final staffSignaturePad = _staffSignatureKey.currentState;
    final operatorSignaturePad = _operatorSignatureKey.currentState;

    try {
      // Convert staff signature to image bytes
      final ui.Image staffImage = await staffSignaturePad!.getData();
      final ByteData? staffSignature =
          await staffImage.toByteData(format: ui.ImageByteFormat.png);

      // Convert operator signature to image bytes
      final ui.Image operatorImage = await operatorSignaturePad!.getData();
      final ByteData? operatorSignature =
          await operatorImage.toByteData(format: ui.ImageByteFormat.png);

      // Call parent onSave with all collected inputs
      widget.onSave(
        isWriteOff: isWriteOff,
        condition: _selectedCondition,
        assignedStaff: widget.assignedStaff,
        attachment: _selectedAttachment,
        staffSignature: staffSignature,
        operatorSignature: operatorSignature,
      );
    } catch (e) {
      // Show error if signatures or saving fails
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header row (title + close button)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Check In Item',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: widget.onClose,
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Show assigned staff if provided
              if (widget.assignedStaff != null)
                Text(
                  'Assigned to: ${widget.assignedStaff}',
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ),

              const SizedBox(height: 20),

              // Dropdown to select item condition
              const Text('Assess item condition:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              const SizedBox(height: 10),
              DropdownButtonFormField<ItemCondition>(
                decoration: InputDecoration(
                  labelText: 'Condition',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                value: _selectedCondition,
                items: ItemCondition.values.map((condition) {
                  return DropdownMenuItem(
                    value: condition,
                    child: Text(condition.name),
                  );
                }).toList(),
                onChanged: (ItemCondition? newValue) {
                  if (newValue != null) {
                    setState(() => _selectedCondition = newValue);
                  }
                },
              ),

              const SizedBox(height: 20),

              // Button to attach condition photo
              OutlinedButton.icon(
                onPressed: _pickAttachment,
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Add Photo of Condition'),
              ),

              // Show preview of attached photo if available
              if (_selectedAttachment != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: Image.file(_selectedAttachment!, height: 100),
                ),

              const SizedBox(height: 20),

              // Staff signature pad
              const Text('Staff Member Signature',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              const SizedBox(height: 10),
              _buildSignaturePad(_staffSignatureKey),

              const SizedBox(height: 20),

              // Operator signature pad
              const Text('Operator Signature',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              const SizedBox(height: 10),
              _buildSignaturePad(_operatorSignatureKey),

              const SizedBox(height: 40),

              // Confirm check-in button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isLoading ? null : () => _handleSave(false),
                  icon: const Icon(Icons.check_circle_outline),
                  label: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Confirm Check In',
                          style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),

              const SizedBox(height: 20),

              // Write-off button (destructive action)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isLoading ? null : () => _handleSave(true),
                  icon: const Icon(Icons.delete_forever_outlined),
                  label: const Text('Write Off Item',
                      style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Reusable signature pad builder
  Widget _buildSignaturePad(GlobalKey<SignatureState> key) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade400, width: 1.0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Signature(
        key: key,
        strokeWidth: 3.0,
      ),
    );
  }
}
