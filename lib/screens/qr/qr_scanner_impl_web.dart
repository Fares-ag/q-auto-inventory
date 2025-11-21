import 'package:flutter/material.dart';

class QrScannerBody extends StatelessWidget {
  const QrScannerBody({super.key, required this.onCodeScanned});

  final ValueChanged<String> onCodeScanned;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.qr_code_scanner, size: 64),
            const SizedBox(height: 16),
            const Text(
              'QR scanning is not available on Web with the current package.\n'
              'Use the mobile app to scan, or paste a code below.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            _ManualCodeEntry(onSubmit: onCodeScanned),
          ],
        ),
      ),
    );
  }
}

class _ManualCodeEntry extends StatefulWidget {
  const _ManualCodeEntry({required this.onSubmit});

  final ValueChanged<String> onSubmit;

  @override
  State<_ManualCodeEntry> createState() => _ManualCodeEntryState();
}

class _ManualCodeEntryState extends State<_ManualCodeEntry> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 280,
          child: TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: 'Enter QR / Asset ID',
            ),
            onSubmitted: (v) {
              if (v.trim().isNotEmpty) widget.onSubmit(v.trim());
            },
          ),
        ),
        const SizedBox(width: 12),
        FilledButton(
          onPressed: () {
            final v = _controller.text.trim();
            if (v.isNotEmpty) widget.onSubmit(v);
          },
          child: const Text('Go'),
        ),
      ],
    );
  }
}

