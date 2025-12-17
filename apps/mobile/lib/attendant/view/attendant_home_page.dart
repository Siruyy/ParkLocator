import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/api/api.dart';
import 'package:mobile/auth/bloc/auth_bloc.dart';
import 'package:mobile/reservations/repository/reservations_repository.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class AttendantHomePage extends StatefulWidget {
  const AttendantHomePage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const AttendantHomePage());
  }

  @override
  State<AttendantHomePage> createState() => _AttendantHomePageState();
}

class _AttendantHomePageState extends State<AttendantHomePage> {
  bool _isScanning = false;
  bool _isLoading = false;

  Future<void> _onScan(BarcodeCapture capture) async {
    if (_isLoading) return;
    
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    
    final qrCode = barcodes.first.rawValue;
    if (qrCode == null) return;

    setState(() {
      _isScanning = false; // Stop scanning UI
      _isLoading = true;
    });

    try {
      final reservation = await context.read<ReservationsRepository>().checkIn(qrCode);
      
      if (mounted) {
        _showResultDialog(
          success: true,
          title: 'Access Granted',
          message: 'Reservation confirmed for ${reservation.venue?.name ?? 'Unknown Venue'}',
          reservation: reservation,
        );
      }
    } catch (e) {
      if (mounted) {
        _showResultDialog(
          success: false,
          title: 'Access Denied',
          message: e.toString().replaceAll('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showResultDialog({
    required bool success,
    required String title,
    required String message,
    Reservation? reservation,
  }) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              success ? Icons.check_circle : Icons.cancel,
              color: success ? Colors.green : Colors.red,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            if (reservation != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    _buildInfoRow('Level', reservation.level?.name ?? 'Unknown Level'),
                    _buildInfoRow('Spot', reservation.spot?.spotNumber ?? 'Unknown Spot'),
                    _buildInfoRow('Plate', 'ABC 1234'), // Mock
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _isScanning = false; // Reset to home state
              });
            },
            child: const Text('Close'),
          ),
          if (success)
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _isScanning = true; // Scan next
                });
              },
              child: const Text('Scan Next'),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isScanning) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Scan QR Code'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => setState(() => _isScanning = false),
          ),
        ),
        body: MobileScanner(
          onDetect: _onScan,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendant Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthBloc>().add(const AuthLogoutRequested()),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF137FEC).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.qr_code_scanner,
                size: 64,
                color: Color(0xFF137FEC),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Ready to Validate',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Scan driver QR codes to grant entry',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 200,
              height: 56,
              child: ElevatedButton(
                onPressed: () => setState(() => _isScanning = true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF137FEC),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt),
                    SizedBox(width: 8),
                    Text('Start Scanning'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
