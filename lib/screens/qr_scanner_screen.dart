import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/auth_secret.dart';
import '../services/storage_service.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  MobileScannerController cameraController = MobileScannerController();
  bool isScanning = true;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (!isScanning) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final String? code = barcode.rawValue;
      if (code != null && code.startsWith('otpauth://totp/')) {
        setState(() {
          isScanning = false;
        });
        _processOTPAuth(code);
        break;
      }
    }
  }

  void _processOTPAuth(String otpAuthUrl) {
    try {
      final uri = Uri.parse(otpAuthUrl);

      // Extract label (account name and issuer)
      String label = uri.path.substring(1); // Remove leading '/'
      String accountName = '';
      String issuer = '';

      if (label.contains(':')) {
        final parts = label.split(':');
        issuer = parts[0];
        accountName = parts[1];
      } else {
        accountName = label;
        issuer = uri.queryParameters['issuer'] ?? 'Unknown';
      }

      final secret = uri.queryParameters['secret'];
      final digits = int.tryParse(uri.queryParameters['digits'] ?? '6') ?? 6;
      final period = int.tryParse(uri.queryParameters['period'] ?? '30') ?? 30;

      if (secret == null || secret.isEmpty) {
        _showErrorDialog('Invalid QR Code: Missing secret');
        return;
      }

      final authSecret = AuthSecret(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: accountName,
        issuer: issuer,
        secret: secret.toUpperCase(),
        digits: digits,
        period: period,
      );

      _showConfirmDialog(authSecret);
    } catch (e) {
      _showErrorDialog('Invalid QR Code format');
    }
  }

  void _showConfirmDialog(AuthSecret secret) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Issuer: ${secret.issuer}'),
            Text('Account: ${secret.name}'),
            const SizedBox(height: 8),
            const Text('Do you want to add this account?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                isScanning = true;
              });
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await StorageService.saveSecret(secret);
              if (mounted) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                isScanning = true;
              });
            },
            child: const Text('OK'),
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
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: () => cameraController.toggleTorch(),
            icon: const Icon(Icons.flash_on),
          ),
          IconButton(
            onPressed: () => cameraController.switchCamera(),
            icon: const Icon(Icons.camera_rear),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(controller: cameraController, onDetect: _onDetect),
          Center(
            child: SizedBox(
              width: 250,
              height: 250,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 2),
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
            ),
          ),
          const Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Point your camera at a QR code',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
