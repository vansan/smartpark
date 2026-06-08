import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../services/firestore_service.dart';
import '../../../models/booking_model.dart';
import '../../../core/theme/app_theme.dart';

class BookingQrScreen extends ConsumerWidget {
  final String bookingId;

  const BookingQrScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Confirmed'),
        leading: BackButton(onPressed: () => context.go('/home')),
      ),
      body: FutureBuilder<BookingModel?>(
        future:
            ref.read(firestoreServiceProvider).getBookingById(bookingId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child:
                  CircularProgressIndicator(color: AppTheme.primaryColor),
            );
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(
              child: Text('Booking not found',
                  style: TextStyle(color: AppTheme.textSecondary)),
            );
          }

          final booking = snapshot.data!;
          final qrData = booking.toQrPayload();
          final dateFmt = DateFormat('dd MMM yyyy');
          final timeFmt = DateFormat('hh:mm a');

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // ── Success Header ──────────────────────────────────────
                const _SuccessBanner(),
                const SizedBox(height: 20),

                // ── Flow Steps ──────────────────────────────────────────
                const _ParkingFlowSteps(currentStep: 1),
                const SizedBox(height: 20),

                // ── QR Code ─────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.25),
                        blurRadius: 30,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    size: 200,
                    backgroundColor: Colors.white,
                    errorCorrectionLevel: QrErrorCorrectLevel.M,
                  ),
                ),

                const SizedBox(height: 12),

                // Instruction banner
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color:
                            AppTheme.primaryColor.withValues(alpha: 0.35)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.qr_code_scanner_rounded,
                          color: AppTheme.primaryColor, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Show this QR to the guard at the entry gate to validate your booking and park your vehicle.',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Booking Details ──────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.local_parking_rounded,
                              color: AppTheme.primaryColor, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              booking.locationName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.freeSlotColor
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text('Active',
                                style: TextStyle(
                                    color: AppTheme.freeSlotColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      _InfoRow(
                          label: 'Slot',
                          value: booking.slotNumber,
                          highlight: true),
                      _InfoRow(
                          label: 'Date',
                          value: dateFmt.format(booking.startTime)),
                      _InfoRow(
                          label: 'Start',
                          value: timeFmt.format(booking.startTime)),
                      _InfoRow(
                          label: 'End',
                          value: timeFmt.format(booking.endTime)),
                      _InfoRow(
                          label: 'Duration',
                          value:
                              '${booking.durationHours} hr${booking.durationHours > 1 ? 's' : ''}'),
                      _InfoRow(
                          label: 'Amount Paid',
                          value:
                              'AED ${booking.amountPaid.toStringAsFixed(2)}'),
                      _InfoRow(
                        label: 'Booking ID',
                        value: booking.bookingId
                            .substring(0, 8)
                            .toUpperCase(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Get Directions ───────────────────────────────────────
                if (booking.hasCoordinates)
                  _DirectionsCard(booking: booking),

                if (booking.hasCoordinates) const SizedBox(height: 20),

                // ── Buttons ──────────────────────────────────────────────
                ElevatedButton.icon(
                  onPressed: () => context.push('/my-bookings'),
                  icon: const Icon(Icons.bookmark_rounded, size: 18),
                  label: const Text('View My Bookings'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => context.go('/home'),
                  icon: const Icon(Icons.home_rounded, size: 18),
                  label: const Text('Back to Home'),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Success Banner ────────────────────────────────────────────────────────────

class _SuccessBanner extends StatelessWidget {
  const _SuccessBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.15),
            AppTheme.primaryColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primaryColor.withValues(alpha: 0.2),
            ),
            child: const Icon(Icons.check_circle_rounded,
                color: AppTheme.primaryColor, size: 30),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Booking Confirmed!',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Payment received · Slot reserved for you',
                  style: TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Parking Flow Steps ────────────────────────────────────────────────────────

class _ParkingFlowSteps extends StatelessWidget {
  final int currentStep; // 0=booked, 1=show QR, 2=park

  const _ParkingFlowSteps({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final steps = [
      (Icons.check_circle_rounded, 'Booked &\nPaid'),
      (Icons.qr_code_rounded, 'Show QR\nat Entry'),
      (Icons.directions_car_rounded, 'Park\nVehicle'),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          for (int i = 0; i < steps.length; i++) ...[
            _StepItem(
              icon: steps[i].$1,
              label: steps[i].$2,
              isDone: i < currentStep,
              isActive: i == currentStep,
            ),
            if (i < steps.length - 1)
              Expanded(
                child: Container(
                  height: 2,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: i < currentStep
                          ? [AppTheme.primaryColor, AppTheme.primaryColor]
                          : [AppTheme.borderColor, AppTheme.borderColor],
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDone;
  final bool isActive;

  const _StepItem({
    required this.icon,
    required this.label,
    required this.isDone,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDone || isActive
        ? AppTheme.primaryColor
        : AppTheme.textSecondary;

    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? AppTheme.primaryColor.withValues(alpha: 0.2)
                : isDone
                    ? AppTheme.primaryColor
                    : AppTheme.borderColor,
            border: isActive
                ? Border.all(color: AppTheme.primaryColor, width: 2)
                : null,
          ),
          child: Icon(
            isDone ? Icons.check_rounded : icon,
            color: isDone ? Colors.black : color,
            size: 18,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color,
            fontSize: 10,
            height: 1.3,
            fontWeight:
                isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

// ─── Info Row ──────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _InfoRow(
      {required this.label, required this.value, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              color: highlight
                  ? AppTheme.primaryColor
                  : AppTheme.textPrimary,
              fontSize: highlight ? 15 : 13,
              fontWeight:
                  highlight ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Directions Card ───────────────────────────────────────────────────────────

class _DirectionsCard extends StatelessWidget {
  final BookingModel booking;
  const _DirectionsCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color(0xFF4285F4).withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.directions_rounded,
                  color: Color(0xFF4285F4), size: 18),
              SizedBox(width: 8),
              Text(
                'Get Directions to Parking',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            booking.locationName,
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final uri = Uri.parse(booking.directionsUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri,
                      mode: LaunchMode.externalApplication);
                }
              },
              icon: const Icon(Icons.map_rounded, size: 18),
              label: const Text('Open in Google Maps'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4285F4),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
