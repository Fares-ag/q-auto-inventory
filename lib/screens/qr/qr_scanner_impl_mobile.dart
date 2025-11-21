import 'dart:io';

import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class QrScannerBody extends StatefulWidget {
  const QrScannerBody({super.key, required this.onCodeScanned});

  final ValueChanged<String> onCodeScanned;

  @override
  State<QrScannerBody> createState() => _QrScannerBodyState();
}

class _QrScannerBodyState extends State<QrScannerBody> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  String? _lastScannedCode;

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller?.pauseCamera();
    } else if (Platform.isIOS) {
      controller?.resumeCamera();
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      final code = scanData.code;
      if (code == null || code == _lastScannedCode) return;
      _lastScannedCode = code;
      widget.onCodeScanned(code);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        QRView(
          key: qrKey,
          onQRViewCreated: _onQRViewCreated,
          overlay: QrScannerOverlayShape(
            borderColor: Colors.white,
            borderRadius: 16,
            borderLength: 30,
            borderWidth: 8,
            cutOutSize: 250,
          ),
        ),
        Positioned(
          bottom: 32,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Text(
                'Point camera at QR code',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

