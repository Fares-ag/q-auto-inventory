import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/firestore_models.dart';
import '../../services/bulk_qr_pdf_service.dart';
import '../../services/firebase_services.dart';
import '../../services/simple_pdf_download.dart';

class BulkQrPrintScreen extends StatefulWidget {
  const BulkQrPrintScreen({super.key});

  static const String routeName = '/bulk-qr';

  @override
  State<BulkQrPrintScreen> createState() => _BulkQrPrintScreenState();
}

class _BulkQrPrintScreenState extends State<BulkQrPrintScreen> {
  bool _isGenerating = false;
  String? _statusMessage;

  Future<void> _generateAndDownload(List<InventoryItem> items) async {
    if (items.isEmpty) return;
    setState(() {
      _isGenerating = true;
      _statusMessage = 'Generating PDF…';
    });
    try {
      final pdfFiles = await BulkQrPdfService.generateBulkQrPdfs(
        items,
        onProgress: (current, total) {
          setState(() {
            _statusMessage = 'Processing $current of $total';
          });
        },
        pageWidthMm: 33,
        pageHeightMm: 106.68,
      );

      for (var i = 0; i < pdfFiles.length; i++) {
        final bytes = pdfFiles[i];
        final filename =
            'qr_labels_part_${i + 1}_of_${pdfFiles.length}_${DateTime.now().millisecondsSinceEpoch}.pdf';
        await SimplePdfDownload.downloadPdf(bytes, filename);
      }

      if (mounted) {
        setState(() => _statusMessage = 'Complete!');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('QR PDF generated successfully.')),
        );
      }
    } catch (error) {
      if (mounted) {
        setState(() => _statusMessage = 'Failed: $error');
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.read<CatalogService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Bulk QR Labels')),
      body: FutureBuilder<List<InventoryItem>>(
        future: catalog.listItems(limit: 500),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final items = snapshot.data ?? const [];
          if (items.isEmpty) {
            return const Center(child: Text('No items to print.'));
          }
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${items.length} items ready for QR printing.'),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _isGenerating ? null : () => _generateAndDownload(items),
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('Generate PDF'),
                ),
                if (_statusMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(_statusMessage!),
                ],
                const SizedBox(height: 24),
                Expanded(
                  child: ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return ListTile(
                        leading: const Icon(Icons.qr_code_2),
                        title: Text(item.name),
                        subtitle: Text(item.assetId),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
