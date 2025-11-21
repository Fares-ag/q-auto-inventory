import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../navigation/app_router.dart';
import '../../services/firebase_services.dart';
import 'qr_scanner_impl_mobile.dart'
    if (dart.library.html) 'qr_scanner_impl_web.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  bool _isHandling = false;

  Future<void> _handleScannedCode(String code) async {
    if (_isHandling) return;
    _isHandling = true;
    try {
      final catalog = context.read<CatalogService>();
      final item = await catalog.getItem(code);

      if (item != null && context.mounted) {
        Navigator.of(context).pushReplacementNamed(
          AppRouter.itemDetailsRoute,
          arguments: ItemDetailArgs(item: item),
        );
        return;
      }

      final items = await catalog.listItems(searchQuery: code, limit: 10);
      if (items.isNotEmpty && context.mounted) {
        Navigator.of(context).pushReplacementNamed(
          AppRouter.itemDetailsRoute,
          arguments: ItemDetailArgs(item: items.first),
        );
      } else if (context.mounted) {
        _showErrorDialog('Item not found', 'No item found with code: $code');
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorDialog('Error', 'Failed to load item: $e');
      }
    } finally {
      _isHandling = false;
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
      ),
      body: QrScannerBody(onCodeScanned: _handleScannedCode),
    );
  }
}

