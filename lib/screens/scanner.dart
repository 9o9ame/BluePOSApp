import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});
  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final controller = MobileScannerController(detectionSpeed: DetectionSpeed.noDuplicates);
  bool handled = false;
  @override
  void dispose() { controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Scan product barcode'), actions: [
      IconButton(onPressed: controller.toggleTorch, icon: const Icon(Icons.flash_on_outlined),
        tooltip:'Toggle torch'),
      IconButton(onPressed: controller.switchCamera,
        icon: const Icon(Icons.flip_camera_android_outlined), tooltip:'Switch camera'),
    ]),
    body: Stack(children: [
      MobileScanner(controller: controller, onDetect: (capture) {
        if (handled) return;
        for (final barcode in capture.barcodes) {
          final value = barcode.rawValue;
          if (value != null && value.isNotEmpty) {
            handled = true;
            Navigator.of(context).pop(value);
            break;
          }
        }
      }),
      Center(child: IgnorePointer(child: Container(
        width: 250, height: 160,
        decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 3),
          borderRadius: BorderRadius.circular(22)),
      ))),
      const Positioned(bottom: 42, left: 16, right: 16,
        child: Text('Align the product barcode inside the frame',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center)),
    ]),
  );
}
