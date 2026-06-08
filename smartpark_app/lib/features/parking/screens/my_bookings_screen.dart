import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../services/firestore_service.dart';
import '../../../models/booking_model.dart';
import '../../../core/theme/app_theme.dart';
import 'package:intl/intl.dart';

class MyBookingsScreen extends ConsumerWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final bookingsStream =
        ref.watch(firestoreServiceProvider).getActiveBookingsForUser(userId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: StreamBuilder<List<BookingModel>>(
        stream: bookingsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child:
                  CircularProgressIndicator(color: AppTheme.primaryColor),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bookmark_border_rounded,
                      size: 64, color: AppTheme.textSecondary),
                  const SizedBox(height: 16),
                  const Text(
                    'No active bookings',
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: ElevatedButton.icon(
                      onPressed: () => context.push('/map'),
                      icon: const Icon(Icons.map_rounded, size: 18),
                      label: const Text('Find Parking'),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final booking = snapshot.data![index];
              return _BookingCard(booking: booking);
            },
          );
        },
      ),
    );
  }
}

class _BookingCard extends ConsumerStatefulWidget {
  final BookingModel booking;

  const _BookingCard({required this.booking});

  @override
  ConsumerState<_BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends ConsumerState<_BookingCard> {
  late Timer _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _remaining = widget.booking.timeRemaining;
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        setState(() {
          _remaining = widget.booking.timeRemaining;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatRemaining(Duration d) {
    if (d == Duration.zero) return 'Expired';
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) return '${h}h ${m}m left';
    return '${m}m left';
  }

  Color _remainingColor(Duration d) {
    if (d == Duration.zero) return AppTheme.bookedSlotColor;
    if (d.inMinutes < 30) return Colors.orange;
    return AppTheme.freeSlotColor;
  }

  Future<void> _releaseBooking() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Release Booking'),
        content: const Text(
          'Are you sure you want to cancel this booking and release the slot?\n\nThis action cannot be undone.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep Booking'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Release',
              style: TextStyle(color: AppTheme.bookedSlotColor),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await ref.read(firestoreServiceProvider).cancelBooking(
          widget.booking.bookingId,
          widget.booking.slotId,
        );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Booking released. Slot is now free.'),
          backgroundColor: AppTheme.freeSlotColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final dateFmt = DateFormat('dd MMM yyyy');
    final timeFmt = DateFormat('hh:mm a');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          // ── Header ────────────────────────────────────────────────────
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_parking_rounded,
                    color: AppTheme.primaryColor, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    booking.locationName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                if (booking.hasCoordinates)
                  IconButton(
                    icon: const Icon(Icons.directions_rounded,
                        color: Color(0xFF4285F4), size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () async {
                      final uri = Uri.parse(booking.directionsUrl);
                      try {
                        await launchUrl(uri,
                            mode: LaunchMode.externalApplication);
                      } catch (e) {
                        debugPrint('Could not launch URL: $e');
                      }
                    },
                    tooltip: 'Get Directions',
                  ),
                if (booking.hasCoordinates) const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.freeSlotColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Active',
                      style: TextStyle(
                        color: AppTheme.freeSlotColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      )),
                ),
              ],
            ),
          ),

          // ── Details ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Slot + countdown row
                Row(
                  children: [
                    Expanded(
                      child: _DetailRow(
                          label: 'Slot', value: booking.slotNumber),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _remainingColor(_remaining)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.timer_rounded,
                              size: 12,
                              color: _remainingColor(_remaining)),
                          const SizedBox(width: 4),
                          Text(
                            _formatRemaining(_remaining),
                            style: TextStyle(
                              color: _remainingColor(_remaining),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _DetailRow(
                    label: 'Date',
                    value: dateFmt.format(booking.startTime)),
                const SizedBox(height: 8),
                _DetailRow(
                    label: 'Start',
                    value: timeFmt.format(booking.startTime)),
                const SizedBox(height: 8),
                _DetailRow(
                    label: 'End', value: timeFmt.format(booking.endTime)),
                const SizedBox(height: 8),
                _DetailRow(
                    label: 'Paid',
                    value:
                        'AED ${booking.amountPaid.toStringAsFixed(2)}'),
                const SizedBox(height: 8),
                _DetailRow(
                  label: 'Booking ID',
                  value: booking.bookingId.substring(0, 8).toUpperCase(),
                ),
                const SizedBox(height: 16),

                // ── Parking Flow Steps ───────────────────────────────────
                _MiniFlowSteps(),
                const SizedBox(height: 16),

                // ── Show QR Button ───────────────────────────────────────
                ElevatedButton.icon(
                  onPressed: () =>
                      context.push('/booking-qr/${booking.bookingId}'),
                  icon: const Icon(Icons.qr_code_2_rounded, size: 20),
                  label: const Text('Show QR to Park'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),

                // ── Get Directions Button ─────────────────────────────────
                if (booking.hasCoordinates)
                  OutlinedButton.icon(
                    onPressed: () async {
                      final uri = Uri.parse(booking.directionsUrl);
                      try {
                        await launchUrl(uri,
                            mode: LaunchMode.externalApplication);
                      } catch (e) {
                        debugPrint('Could not launch URL: $e');
                      }
                    },
                    icon: const Icon(Icons.directions_rounded, size: 18),
                    label: const Text('Get Directions'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF4285F4),
                      side: const BorderSide(
                          color: Color(0xFF4285F4), width: 1.5),
                    ),
                  ),

                if (booking.hasCoordinates) const SizedBox(height: 8),

                // ── Release Button ────────────────────────────────────────
                OutlinedButton.icon(
                  onPressed: _releaseBooking,
                  icon: const Icon(Icons.cancel_outlined, size: 18),
                  label: const Text('Release Booking'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.bookedSlotColor,
                    side: const BorderSide(
                        color: AppTheme.bookedSlotColor, width: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Mini Flow Steps ───────────────────────────────────────────────────────────

class _MiniFlowSteps extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _MiniStep(
            icon: Icons.check_circle_rounded,
            label: 'Booked',
            isDone: true,
          ),
          _Connector(done: true),
          _MiniStep(
            icon: Icons.qr_code_rounded,
            label: 'Show QR',
            isDone: false,
            isActive: true,
          ),
          _Connector(done: false),
          _MiniStep(
            icon: Icons.directions_car_rounded,
            label: 'Park',
            isDone: false,
          ),
        ],
      ),
    );
  }
}

class _MiniStep extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDone;
  final bool isActive;

  const _MiniStep({
    required this.icon,
    required this.label,
    required this.isDone,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDone || isActive
        ? AppTheme.primaryColor
        : AppTheme.textSecondary;
    return Column(
      children: [
        Icon(isDone ? Icons.check_circle_rounded : icon, color: color, size: 18),
        const SizedBox(height: 3),
        Text(label,
            style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal)),
      ],
    );
  }
}

class _Connector extends StatelessWidget {
  final bool done;
  const _Connector({required this.done});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 2,
      margin: const EdgeInsets.only(bottom: 12, left: 4, right: 4),
      color: done ? AppTheme.primaryColor : AppTheme.borderColor,
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 13)),
        Text(value,
            style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}
