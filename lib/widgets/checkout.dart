// lib/widgets/checkout.dart

import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_signature_pad/flutter_signature_pad.dart';

class CheckoutWidget extends StatefulWidget {
  // Callback for when checkout is saved (assignTo + two signatures)
  final Function(String assignTo, ByteData? assigneeSignature,
      ByteData? operatorSignature) onSave;

  // Optional callback for closing the widget
  final VoidCallback? onClose;

  const CheckoutWidget({
    Key? key,
    required this.onSave,
    this.onClose,
  }) : super(key: key);

  @override
  State<CheckoutWidget> createState() => _CheckoutWidgetState();
}

class _CheckoutWidgetState extends State<CheckoutWidget> {
  // Key for validating the checkout form
  final _formKey = GlobalKey<FormState>();

  // Text controller for "Assign To" field
  final _assignToController = TextEditingController();

  // Keys for capturing signatures
  final GlobalKey<SignatureState> _assigneeSignatureKey =
      GlobalKey<SignatureState>();
  final GlobalKey<SignatureState> _operatorSignatureKey =
      GlobalKey<SignatureState>();

  bool _isLoading = false; // Tracks whether save process is ongoing

  @override
  void dispose() {
    // Clean up controller to avoid memory leaks
    _assignToController.dispose();
    super.dispose();
  }

  // Handles checkout save action
  void _saveCheckout() async {
    // Validate the form (checks "Assign To" input)
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final assigneeSignaturePad = _assigneeSignatureKey.currentState;
      final operatorSignaturePad = _operatorSignatureKey.currentState;

      // Ensure both signatures are captured before saving
      if (assigneeSignaturePad == null || assigneeSignaturePad.points.isEmpty) {
        throw 'Assignee signature is required.';
      }
      if (operatorSignaturePad == null || operatorSignaturePad.points.isEmpty) {
        throw 'Operator signature is required.';
      }

      // Convert assignee signature to image bytes
      final ui.Image assigneeImage = await assigneeSignaturePad.getData();
      final ByteData? assigneeSignature =
          await assigneeImage.toByteData(format: ui.ImageByteFormat.png);

      // Convert operator signature to image bytes
      final ui.Image operatorImage = await operatorSignaturePad.getData();
      final ByteData? operatorSignature =
          await operatorImage.toByteData(format: ui.ImageByteFormat.png);

      // Call parent onSave callback with collected data
      widget.onSave(
        _assignToController.text.trim(),
        assigneeSignature,
        operatorSignature,
      );
    } catch (e) {
      // Show error message if something goes wrong
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
            topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey, // Ensures validation logic works
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header row (title + close button)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Checkout Item',
                        style: TextStyle(
                            fontSize: 28, fontWeight: FontWeight.bold)),
                    IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: widget.onClose),
                  ],
                ),
                const SizedBox(height: 30),

                // Text field for entering assignee name
                TextFormField(
                  controller: _assignToController,
                  decoration: InputDecoration(
                    hintText: 'Assign To',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter a name' : null,
                ),

                const SizedBox(height: 20),

                // Signature pad for assignee
                const Text('Assignee Signature',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                const SizedBox(height: 10),
                _buildSignaturePad(_assigneeSignatureKey),

                const SizedBox(height: 20),

                // Signature pad for operator
                const Text('Operator Signature',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                const SizedBox(height: 10),
                _buildSignaturePad(_operatorSignatureKey),

                const SizedBox(height: 40),

                // Confirm checkout button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isLoading ? null : _saveCheckout,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Confirm Checkout',
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

  // Helper widget for building a signature pad
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
