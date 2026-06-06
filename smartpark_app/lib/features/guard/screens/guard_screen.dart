import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';
import '../../../services/booking_service.dart';
import '../../../core/theme/app_theme.dart';

class GuardScreen extends ConsumerStatefulWidget {
  const GuardScreen({super.key});

  @override
  ConsumerState<GuardScreen> createState() => _GuardScreenState();
}

class _GuardScreenState extends ConsumerState<GuardScreen> {
  MobileScannerController? _scannerController;
  bool _isValidating = false;
  QrValidationResult? _result;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isValidating || _result != null) return;

    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;

    final payload = barcode!.rawValue!;
    setState(() => _isValidating = true);

    // Stop scanner while validating
    await _scannerController?.stop();

    final result = await ref
        .read(bookingServiceProvider)
        .validateQrAndOccupy(payload);

    if (mounted) {
      setState(() {
        _isValidating = false;
        _result = result;
      });
    }
  }

  void _resetScanner() {
    setState(() => _result = null);
    _scannerController?.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guard Mode'),
        leading: BackButton(onPressed: () => context.pop()),
        actions: [
          IconButton(
            icon: const Icon(Icons.flashlight_on_rounded),
            onPressed: () => _scannerController?.toggleTorch(),
            tooltip: 'Toggle Torch',
          ),
        ],
      ),
      body: Column(
        children: [
          // Guard Mode badge
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            color: Colors.white.withValues(alpha: 0.08),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.security_rounded,
                  color: Colors.white,
                  size: 16,
                ),
                SizedBox(width: 8),
                Text(
                  'GUARD MODE — POC SIMULATION',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: _result != null ? _buildResultView() : _buildScannerView(),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerView() {
    return Stack(
      children: [
        MobileScanner(controller: _scannerController!, onDetect: _onDetect),

        // Scan overlay
        CustomPaint(painter: _ScanFramePainter(), child: Container()),

        // Bottom label
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: _isValidating
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Validating...',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    )
                  : const Text(
                      'Point camera at user QR code',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultView() {
    final isValid = _result!.valid;
    final color = isValid ? AppTheme.freeSlotColor : AppTheme.bookedSlotColor;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 24),

          // Result Icon
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.15),
              border: Border.all(color: color, width: 2),
            ),
            child: Icon(
              isValid ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: color,
              size: 56,
            ),
          ),

          const SizedBox(height: 24),

          Text(
            _result!.message,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          if (isValid) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.freeSlotColor.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  _ResultRow(
                    label: 'Location',
                    value: _result!.locationName ?? '',
                  ),
                  const SizedBox(height: 10),
                  _ResultRow(label: 'Slot', value: _result!.slotNumber ?? ''),
                  const SizedBox(height: 10),
                  _ResultRow(
                    label: 'Booking ID',
                    value: (_result!.bookingId ?? '')
                        .substring(0, 8)
                        .toUpperCase(),
                  ),
                  const SizedBox(height: 10),
                  _ResultRow(label: 'Status', value: '✅ Slot Marked Occupied'),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.bookedSlotColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.bookedSlotColor.withValues(alpha: 0.3),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: AppTheme.bookedSlotColor,
                    size: 18,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Do not allow entry. Booking is invalid or already used.',
                      style: TextStyle(
                        color: AppTheme.bookedSlotColor,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 32),

          ElevatedButton.icon(
            onPressed: _resetScanner,
            icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
            label: const Text('Scan Another QR'),
          ),

          const SizedBox(height: 12),

          OutlinedButton.icon(
            onPressed: () => context.go('/home'),
            icon: const Icon(Icons.home_rounded, size: 18),
            label: const Text('Back to Home'),
          ),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;

  const _ResultRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _ScanFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primaryColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final double cx = size.width / 2;
    final double cy = size.height / 2;
    const double boxSize = 220;
    const double cornerLen = 24;

    final rect = Rect.fromCenter(
      center: Offset(cx, cy),
      width: boxSize,
      height: boxSize,
    );

    // Draw 4 corner brackets
    final corners = [
      [
        rect.topLeft,
        Offset(rect.left + cornerLen, rect.top),
        Offset(rect.left, rect.top + cornerLen),
      ],
      [
        rect.topRight,
        Offset(rect.right - cornerLen, rect.top),
        Offset(rect.right, rect.top + cornerLen),
      ],
      [
        rect.bottomLeft,
        Offset(rect.left + cornerLen, rect.bottom),
        Offset(rect.left, rect.bottom - cornerLen),
      ],
      [
        rect.bottomRight,
        Offset(rect.right - cornerLen, rect.bottom),
        Offset(rect.right, rect.bottom - cornerLen),
      ],
    ];

    for (final corner in corners) {
      final path = Path()
        ..moveTo(corner[1].dx, corner[1].dy)
        ..lineTo(corner[0].dx, corner[0].dy)
        ..lineTo(corner[2].dx, corner[2].dy);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
