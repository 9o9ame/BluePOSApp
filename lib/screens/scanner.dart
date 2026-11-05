import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Camera barcode scanner with explicit lifecycle, errors and manual fallback.
/// Returned value is resolved and authorized by the calling server API.
class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen>
    with WidgetsBindingObserver {
  late final MobileScannerController controller = MobileScannerController(
    autoStart: false,
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool handled = false;
  bool starting = false;
  bool disposed = false;
  MobileScannerErrorCode? cameraError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _startCamera();
    });
  }

  Future<void> _startCamera() async {
    if (starting || handled || disposed) return;
    starting = true;
    if (mounted) setState(() => cameraError = null);
    try {
      await controller.start();
    } on MobileScannerException catch (ex) {
      if (mounted) setState(() => cameraError = ex.errorCode);
    } catch (_) {
      if (mounted) setState(() => cameraError = MobileScannerErrorCode.genericError);
    } finally {
      starting = false;
    }
  }

  Future<void> _retryCamera() async {
    if (starting || handled) return;
    try {
      await controller.stop();
    } catch (_) {
      // Retry can still recover when the device never initialized.
    }
    await _startCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Android's permission prompt can temporarily make the app inactive.
    if (!controller.value.hasCameraPermission || handled || disposed) return;
    switch (state) {
      case AppLifecycleState.resumed:
        _startCamera();
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        controller.stop();
    }
  }

  @override
  void dispose() {
    disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    controller.dispose();
    super.dispose();
  }

  String _errorMessage(MobileScannerErrorCode error) {
    switch (error) {
      case MobileScannerErrorCode.permissionDenied:
        return 'Camera permission denied. Enable camera access in Android Settings.';
      case MobileScannerErrorCode.unsupported:
        return 'Scanning is not supported by this camera.';
      default:
        return 'Camera could not start. Retry or enter the barcode manually.';
    }
  }

  Widget _errorView(MobileScannerErrorCode error) => Center(
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 22),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF152139),
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.videocam_off_outlined, color: Colors.white, size: 38),
        const SizedBox(height: 12),
        const Text('Camera unavailable', style: TextStyle(
          color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
        const SizedBox(height: 7),
        Text(_errorMessage(error), textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 15),
        FilledButton.icon(onPressed: starting ? null : _retryCamera,
          icon: const Icon(Icons.refresh_rounded), label: const Text('Retry camera')),
        TextButton(onPressed: _manualBarcode, child: const Text('Enter barcode manually')),
      ]),
    ),
  );

  Future<void> _manualBarcode() async {
    final field = TextEditingController();
    try {
      final result = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Enter barcode'),
          content: TextField(
            controller: field,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              hintText: 'Scan code / product barcode'),
            onSubmitted: (text) {
              if (text.trim().isNotEmpty) Navigator.pop(dialogContext, text.trim());
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel')),
            FilledButton(onPressed: () {
              final value = field.text.trim();
              if (value.isNotEmpty) Navigator.pop(dialogContext, value);
            }, child: const Text('Use barcode')),
          ],
        ),
      );
      if (result != null && result.isNotEmpty && mounted && !handled) {
        handled = true;
        Navigator.of(context).pop(result);
      }
    } finally {
      field.dispose();
    }
  }

  void _handleDetection(BarcodeCapture capture) {
    if (handled || !mounted) return;
    for (final barcode in capture.barcodes) {
      final code = barcode.rawValue?.trim();
      if (code != null && code.isNotEmpty) {
        handled = true;
        Navigator.of(context).pop(code);
        return;
      }
    }
  }

  Future<void> _cameraAction(Future<void> Function() action) async {
    if (handled || starting) return;
    try {
      await action();
    } catch (_) {
      if (mounted) setState(() => cameraError = MobileScannerErrorCode.genericError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan Barcode', maxLines: 1,
          overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(onPressed: () => _cameraAction(controller.toggleTorch),
            tooltip: 'Toggle flashlight', icon: const Icon(Icons.flash_on_outlined)),
          IconButton(onPressed: () => _cameraAction(controller.switchCamera),
            tooltip: 'Switch camera', icon: const Icon(Icons.cameraswitch_outlined)),
        ],
      ),
      body: Stack(fit: StackFit.expand, children: [
        MobileScanner(
          controller: controller,
          onDetect: _handleDetection,
          errorBuilder: (context, error, child) =>
            _errorView(error.errorCode),
        ),
        if (cameraError != null)
          ColoredBox(color: Colors.black, child: _errorView(cameraError!)),
        if (cameraError == null)
          Center(child: IgnorePointer(
            child: Container(
              width: 270, height: 178,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(22),
              ),
            ),
          )),
        Positioned(
          left: 18, right: 18, bottom: 24,
          child: SafeArea(top: false, child: Column(
            mainAxisSize: MainAxisSize.min, children: [
              if (cameraError == null) const Text(
                'Align the product barcode inside the frame',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white,
                  fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: _manualBarcode,
                icon: Icon(Icons.keyboard_alt_outlined, color: accent),
                label: const Text('Enter barcode manually'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white54),
                  backgroundColor: const Color(0xFF17243F),
                ),
              ),
            ],
          )),
        ),
      ]),
    );
  }
}
