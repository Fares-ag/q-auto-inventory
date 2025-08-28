// lib/widgets/checkin_widget.dart

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_signature_pad/flutter_signature_pad.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

enum ItemCondition { Excellent, Good, Fair, Poor }

class CheckinWidget extends StatefulWidget {
  final VoidCallback onClose;
  final Function({
    required bool isWriteOff,
    required ItemCondition condition,
    required String? assignedStaff,
    required File? attachment,
    required Uint8List? staffSignature,
    required Uint8List? operatorSignature,
  }) onSave;
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
  ItemCondition _selectedCondition = ItemCondition.Good;
  bool _isLoading = false;
  File? _selectedAttachment;
  final ImagePicker _picker = ImagePicker();
  final GlobalKey<SignatureState> _staffSignatureKey =
      GlobalKey<SignatureState>();
  final GlobalKey<SignatureState> _operatorSignatureKey =
      GlobalKey<SignatureState>();

  Future<void> _pickAttachment() async {
    final XFile? image =
        await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (image != null) {
      setState(() {
        _selectedAttachment = File(image.path);
      });
    }
  }

  void _handleSave(bool isWriteOff) async {
    setState(() => _isLoading = true);

    final staffSignaturePad = _staffSignatureKey.currentState;
    final operatorSignaturePad = _operatorSignatureKey.currentState;

    try {
      final ui.Image staffImage = await staffSignaturePad!.getData();
      final ByteData? staffByteData =
          await staffImage.toByteData(format: ui.ImageByteFormat.png);

      final ui.Image operatorImage = await operatorSignaturePad!.getData();
      final ByteData? operatorByteData =
          await operatorImage.toByteData(format: ui.ImageByteFormat.png);

      widget.onSave(
        isWriteOff: isWriteOff,
        condition: _selectedCondition,
        assignedStaff: widget.assignedStaff,
        attachment: _selectedAttachment,
        staffSignature: staffByteData?.buffer.asUint8List(),
        operatorSignature: operatorByteData?.buffer.asUint8List(),
      );
    } catch (e) {
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
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Check In Item',
                      style:
                          TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: widget.onClose,
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                if (widget.assignedStaff != null)
                  Text(
                    'Assigned to: ${widget.assignedStaff}',
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                const SizedBox(height: 20),
                const Text('Assess item condition:',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
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
                OutlinedButton.icon(
                  onPressed: _pickAttachment,
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Add Photo of Condition'),
                ),
                if (_selectedAttachment != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Image.file(_selectedAttachment!, height: 100),
                  ),
                const SizedBox(height: 20),
                const Text('Staff Member Signature',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                const SizedBox(height: 10),
                _buildSignaturePad(_staffSignatureKey),
                const SizedBox(height: 20),
                const Text('Operator Signature',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                const SizedBox(height: 10),
                _buildSignaturePad(_operatorSignatureKey),
                const SizedBox(height: 40),
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
                    icon: const Icon(Icons.check_circle_outline,
                        color: Colors.white),
                    label: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Confirm Check In',
                            style:
                                TextStyle(fontSize: 18, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 20),
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
      ),
    );
  }

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
