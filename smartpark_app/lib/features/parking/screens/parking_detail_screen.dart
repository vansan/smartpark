import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../services/firestore_service.dart';
import '../../../models/parking_slot_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/booking_service.dart';

class ParkingDetailScreen extends ConsumerWidget {
  final String locationId;
  final String locationName;
  final double locationLat;
  final double locationLng;

  const ParkingDetailScreen({
    super.key,
    required this.locationId,
    required this.locationName,
    this.locationLat = 0.0,
    this.locationLng = 0.0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slotsStream =
        ref.watch(firestoreServiceProvider).getSlotsForLocation(locationId);

    return Scaffold(
      appBar: AppBar(
        title: Text(locationName),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: Column(
        children: [
          // Legend
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _LegendItem(color: AppTheme.freeSlotColor, label: 'Free — Tap to book'),
                _LegendItem(color: AppTheme.bookedSlotColor, label: 'Reserved'),
                _LegendItem(
                    color: AppTheme.occupiedSlotColor, label: 'Occupied'),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<List<ParkingSlotModel>>(
              stream: slotsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                        color: AppTheme.primaryColor),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('No slots available',
                        style:
                            TextStyle(color: AppTheme.textSecondary)),
                  );
                }

                final slots = snapshot.data!;
                final freeCount =
                    slots.where((s) => s.isFree).length;

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Row(
                        children: [
                          Text(
                            '$freeCount of ${slots.length} slots available',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.5,
                        ),
                        itemCount: slots.length,
                        itemBuilder: (context, index) {
                          final slot = slots[index];
                          return _SlotCard(
                            slot: slot,
                            locationName: locationName,
                            onBook: slot.isFree
                                ? () => _showBookingBottomSheet(
                                    context, slot)
                                : null,
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showBookingBottomSheet(BuildContext context, ParkingSlotModel slot) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BookingBottomSheet(
        slot: slot,
        locationId: locationId,
        locationName: locationName,
        locationLat: locationLat,
        locationLng: locationLng,
      ),
    );
  }
}

// ─── Booking Bottom Sheet ─────────────────────────────────────────────────────

class _BookingBottomSheet extends StatefulWidget {
  final ParkingSlotModel slot;
  final String locationId;
  final String locationName;
  final double locationLat;
  final double locationLng;

  const _BookingBottomSheet({
    required this.slot,
    required this.locationId,
    required this.locationName,
    required this.locationLat,
    required this.locationLng,
  });

  @override
  State<_BookingBottomSheet> createState() => _BookingBottomSheetState();
}

class _BookingBottomSheetState extends State<_BookingBottomSheet> {
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  int _durationHours = 1;

  DateTime get _startDateTime {
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
  }

  DateTime get _endDateTime =>
      _startDateTime.add(Duration(hours: _durationHours));

  double get _total =>
      BookingService.calculateTotal(_durationHours);

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.primaryColor,
            surface: AppTheme.cardColor,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.primaryColor,
            surface: AppTheme.cardColor,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('EEE, dd MMM yyyy');
    final timeFmt = DateFormat('hh:mm a');
    final endFmt = DateFormat('hh:mm a, dd MMM');

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.local_parking_rounded,
                    color: AppTheme.primaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.locationName,
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12)),
                    Text(
                      'Slot ${widget.slot.slotNumber}',
                      style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Date Picker Row
          _PickerRow(
            icon: Icons.calendar_today_rounded,
            label: 'Date',
            value: dateFmt.format(_selectedDate),
            onTap: _pickDate,
          ),
          const SizedBox(height: 12),

          // Time Picker Row
          _PickerRow(
            icon: Icons.access_time_rounded,
            label: 'Start Time',
            value: timeFmt.format(_startDateTime),
            onTap: _pickTime,
          ),
          const SizedBox(height: 12),

          // Duration
          _DurationSelector(
            value: _durationHours,
            onChanged: (v) => setState(() => _durationHours = v),
          ),
          const SizedBox(height: 16),

          // End time label
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Row(
              children: [
                const Icon(Icons.flag_rounded,
                    color: AppTheme.textSecondary, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Ends at: ${endFmt.format(_endDateTime)}',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 13),
                ),
                const Spacer(),
                Text(
                  'AED ${_total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Proceed button
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              context.push(
                '/payment-summary',
                extra: {
                  'slot': widget.slot,
                  'locationId': widget.locationId,
                  'locationName': widget.locationName,
                  'startTime': _startDateTime,
                  'endTime': _endDateTime,
                  'durationHours': _durationHours,
                  'total': _total,
                  'locationLat': widget.locationLat,
                  'locationLng': widget.locationLng,
                },
              );
            },
            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
            label: const Text('Proceed to Payment'),
          ),
        ],
      ),
    );
  }
}

// ─── Helper Widgets ────────────────────────────────────────────────────────────

class _PickerRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _PickerRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primaryColor, size: 18),
            const SizedBox(width: 10),
            Text(label,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 13)),
            const Spacer(),
            Text(value,
                style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded,
                color: AppTheme.textSecondary, size: 18),
          ],
        ),
      ),
    );
  }
}

class _DurationSelector extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _DurationSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final durations = [1, 2, 3, 4, 8];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Duration',
            style:
                TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        const SizedBox(height: 8),
        Row(
          children: durations.map((h) {
            final selected = h == value;
            return Expanded(
              child: GestureDetector(
                onTap: () => onChanged(h),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppTheme.primaryColor
                        : AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selected
                          ? AppTheme.primaryColor
                          : AppTheme.borderColor,
                    ),
                  ),
                  child: Text(
                    '${h}h',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: selected ? Colors.black : AppTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ─── Slot Card ─────────────────────────────────────────────────────────────────

class _SlotCard extends StatelessWidget {
  final ParkingSlotModel slot;
  final String locationName;
  final VoidCallback? onBook;

  const _SlotCard({
    required this.slot,
    required this.locationName,
    this.onBook,
  });

  Color get _statusColor {
    if (slot.isFree) return AppTheme.freeSlotColor;
    if (slot.isBooked) return AppTheme.bookedSlotColor;
    return AppTheme.occupiedSlotColor;
  }

  String get _statusLabel {
    if (slot.isFree) return 'Available';
    if (slot.isBooked) return 'Reserved';
    return 'Occupied';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onBook,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: slot.isFree
                ? AppTheme.freeSlotColor.withValues(alpha: 0.5)
                : AppTheme.borderColor,
            width: slot.isFree ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  Icons.directions_car_rounded,
                  color: _statusColor,
                  size: 22,
                ),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _statusColor,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slot.slotNumber,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  _statusLabel,
                  style: TextStyle(
                    color: _statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 12)),
      ],
    );
  }
}
