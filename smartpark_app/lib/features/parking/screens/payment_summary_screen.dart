import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../services/booking_service.dart';
import '../../../models/parking_slot_model.dart';
import '../../../core/theme/app_theme.dart';

class PaymentSummaryScreen extends ConsumerStatefulWidget {
  final ParkingSlotModel slot;
  final String locationId;
  final String locationName;
  final DateTime startTime;
  final DateTime endTime;
  final int durationHours;
  final double total;
  final double locationLat;
  final double locationLng;

  const PaymentSummaryScreen({
    super.key,
    required this.slot,
    required this.locationId,
    required this.locationName,
    required this.startTime,
    required this.endTime,
    required this.durationHours,
    required this.total,
    this.locationLat = 0.0,
    this.locationLng = 0.0,
  });

  @override
  ConsumerState<PaymentSummaryScreen> createState() =>
      _PaymentSummaryScreenState();
}

class _PaymentSummaryScreenState extends ConsumerState<PaymentSummaryScreen> {
  bool _isProcessing = false;

  double get _subtotal =>
      BookingService.calculateSubtotal(widget.durationHours);
  double get _vat => BookingService.calculateVat(widget.durationHours);

  Future<void> _confirmPayment() async {
    setState(() => _isProcessing = true);

    // Simulate payment gateway processing (1.5 sec)
    await Future.delayed(const Duration(milliseconds: 1500));

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null || !mounted) {
      setState(() => _isProcessing = false);
      return;
    }

    final result = await ref.read(bookingServiceProvider).bookSlot(
          userId: userId,
          slot: widget.slot,
          locationName: widget.locationName,
          startTime: widget.startTime,
          endTime: widget.endTime,
          durationHours: widget.durationHours,
          amountPaid: widget.total,
          locationLat: widget.locationLat,
          locationLng: widget.locationLng,
        );

    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (result.success) {
      context.go('/booking-qr/${result.bookingId}');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ ${result.errorMessage}'),
          backgroundColor: AppTheme.bookedSlotColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd MMM yyyy');
    final timeFmt = DateFormat('hh:mm a');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Summary'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Booking Details Card ──────────────────────────────────────
            _SectionCard(
              children: [
                _SectionHeader(
                  icon: Icons.local_parking_rounded,
                  iconColor: AppTheme.primaryColor,
                  title: 'Booking Details',
                ),
                const SizedBox(height: 16),
                _InfoRow(
                  label: 'Location',
                  value: widget.locationName,
                ),
                _InfoRow(label: 'Slot', value: widget.slot.slotNumber, highlight: true),
                _InfoRow(label: 'Date', value: dateFmt.format(widget.startTime)),
                _InfoRow(
                  label: 'Start Time',
                  value: timeFmt.format(widget.startTime),
                ),
                _InfoRow(
                  label: 'End Time',
                  value: timeFmt.format(widget.endTime),
                ),
                _InfoRow(
                  label: 'Duration',
                  value: '${widget.durationHours} hour${widget.durationHours > 1 ? 's' : ''}',
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Price Breakdown ────────────────────────────────────────────
            _SectionCard(
              children: [
                _SectionHeader(
                  icon: Icons.receipt_long_rounded,
                  iconColor: AppTheme.primaryColor,
                  title: 'Price Breakdown',
                ),
                const SizedBox(height: 16),
                _PriceRow(
                  label:
                      'Parking (AED 5.00 × ${widget.durationHours} hr)',
                  value: _subtotal,
                ),
                _PriceRow(label: 'VAT (5%)', value: _vat),
                const Divider(height: 24),
                _PriceRow(
                  label: 'Total',
                  value: widget.total,
                  isTotal: true,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Payment Method ─────────────────────────────────────────────
            _SectionCard(
              children: [
                _SectionHeader(
                  icon: Icons.payment_rounded,
                  iconColor: AppTheme.primaryColor,
                  title: 'Payment Method',
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color:
                            AppTheme.primaryColor.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.credit_card_rounded,
                          color: AppTheme.primaryColor, size: 22),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Credit / Debit Card',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              '**** **** **** 4242',
                              style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color:
                              AppTheme.primaryColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Default',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.lock_outline_rounded,
                        size: 13, color: AppTheme.textSecondary),
                    const SizedBox(width: 5),
                    Text(
                      'Prepaid · Secure · Non-refundable after slot entry',
                      style: TextStyle(
                          fontSize: 11,
                          color:
                              AppTheme.textSecondary.withValues(alpha: 0.8)),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 32),

            // ── Confirm Button ─────────────────────────────────────────────
            _isProcessing
                ? Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.black),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Processing Payment...',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: () => _confirmPayment(),
                    icon: const Icon(Icons.lock_rounded, size: 18),
                    label: Text(
                        'Confirm & Pay AED ${widget.total.toStringAsFixed(2)}'),
                  ),

            const SizedBox(height: 12),

            OutlinedButton(
              onPressed: () => context.pop(),
              child: const Text('← Change Details'),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;

  const _SectionHeader(
      {required this.icon, required this.iconColor, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            )),
      ],
    );
  }
}

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
          Text(value,
              style: TextStyle(
                color:
                    highlight ? AppTheme.primaryColor : AppTheme.textPrimary,
                fontWeight:
                    highlight ? FontWeight.bold : FontWeight.w500,
                fontSize: highlight ? 15 : 13,
              )),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final double value;
  final bool isTotal;

  const _PriceRow(
      {required this.label, required this.value, this.isTotal = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                color: isTotal
                    ? AppTheme.textPrimary
                    : AppTheme.textSecondary,
                fontSize: isTotal ? 15 : 13,
                fontWeight:
                    isTotal ? FontWeight.bold : FontWeight.normal,
              )),
          Text(
            'AED ${value.toStringAsFixed(2)}',
            style: TextStyle(
              color: isTotal
                  ? AppTheme.primaryColor
                  : AppTheme.textPrimary,
              fontSize: isTotal ? 16 : 13,
              fontWeight:
                  isTotal ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
