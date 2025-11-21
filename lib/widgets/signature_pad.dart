import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

class SignaturePad extends StatefulWidget {
  const SignaturePad({
    super.key,
    required this.onSignatureSaved,
    this.title = 'Sign Here',
  });

  final ValueChanged<Uint8List> onSignatureSaved;
  final String title;

  @override
  State<SignaturePad> createState() => _SignaturePadState();
}

class _SignaturePadState extends State<SignaturePad> {
  final SignatureController _controller = SignatureController(
    penStrokeWidth: 2,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveSignature() async {
    if (_controller.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a signature')),
      );
      return;
    }

    final signature = await _controller.toPngBytes();
    if (signature != null) {
      widget.onSignatureSaved(signature);
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            tooltip: 'Clear',
            onPressed: () => _controller.clear(),
          ),
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Save',
            onPressed: _saveSignature,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Signature(
                controller: _controller,
                backgroundColor: Colors.white,
                height: double.infinity,
                width: double.infinity,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _controller.clear(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Clear'),
                ),
                FilledButton.icon(
                  onPressed: _saveSignature,
                  icon: const Icon(Icons.check),
                  label: const Text('Save Signature'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

