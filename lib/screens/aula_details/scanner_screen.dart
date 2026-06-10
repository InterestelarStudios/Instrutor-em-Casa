import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key, required this.onScan});
  final Function(String) onScan;

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  bool scanned = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Escanear Check-in')),
      body: MobileScanner(
        onDetect: (capture) {
          if (scanned) return;
          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            if (barcode.rawValue != null) {
              scanned = true;
              widget.onScan(barcode.rawValue!);
              Navigator.pop(context);
              break;
            }
          }
        },
      ),
    );
  }
}
