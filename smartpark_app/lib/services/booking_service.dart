import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../core/constants/app_constants.dart';
import '../models/booking_model.dart';
import '../models/parking_slot_model.dart';

final bookingServiceProvider =
    Provider<BookingService>((ref) => BookingService());

class BookingResult {
  final bool success;
  final String? bookingId;
  final String? errorMessage;

  const BookingResult({
    required this.success,
    this.bookingId,
    this.errorMessage,
  });
}

class BookingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  /// Rate per hour in AED
  static const double ratePerHour = 5.0;
  static const double vatRate = 0.05;

  static double calculateSubtotal(int hours) => ratePerHour * hours;
  static double calculateVat(int hours) =>
      calculateSubtotal(hours) * vatRate;
  static double calculateTotal(int hours) =>
      calculateSubtotal(hours) + calculateVat(hours);

  /// Books a slot using a Firestore transaction to prevent double-booking.
  Future<BookingResult> bookSlot({
    required String userId,
    required ParkingSlotModel slot,
    required String locationName,
    required DateTime startTime,
    required DateTime endTime,
    required int durationHours,
    required double amountPaid,
  }) async {
    final slotRef = _db
        .collection(AppConstants.parkingSlotsCollection)
        .doc(slot.slotId);

    try {
      String? bookingId;

      await _db.runTransaction((transaction) async {
        final slotDoc = await transaction.get(slotRef);

        if (!slotDoc.exists) {
          throw Exception('Slot not found');
        }

        final currentStatus = slotDoc.data()?['status'] as String?;
        if (currentStatus != AppConstants.slotFree) {
          throw Exception('Slot is no longer available');
        }

        // Generate booking
        bookingId = _uuid.v4();
        final bookingRef = _db
            .collection(AppConstants.bookingsCollection)
            .doc(bookingId);

        final booking = BookingModel(
          bookingId: bookingId!,
          userId: userId,
          slotId: slot.slotId,
          locationId: slot.locationId,
          slotNumber: slot.slotNumber,
          locationName: locationName,
          createdAt: DateTime.now(),
          startTime: startTime,
          endTime: endTime,
          durationHours: durationHours,
          amountPaid: amountPaid,
          status: AppConstants.bookingActive,
        );

        // Update slot status atomically
        transaction.update(slotRef, {'status': AppConstants.slotBooked});
        transaction.set(bookingRef, booking.toMap());
      });

      return BookingResult(success: true, bookingId: bookingId);
    } on FirebaseException catch (e) {
      return BookingResult(
          success: false, errorMessage: e.message ?? 'Booking failed');
    } catch (e) {
      return BookingResult(success: false, errorMessage: e.toString());
    }
  }

  /// Validates a QR code scan and marks the slot as occupied.
  Future<QrValidationResult> validateQrAndOccupy(String qrPayload) async {
    try {
      // Parse QR payload
      final Map<String, dynamic> data = _parseQrPayload(qrPayload);
      final String bookingId = data['bookingId'];
      final String slotId = data['slotId'];

      final bookingRef = _db
          .collection(AppConstants.bookingsCollection)
          .doc(bookingId);
      final slotRef = _db
          .collection(AppConstants.parkingSlotsCollection)
          .doc(slotId);

      late QrValidationResult result;

      await _db.runTransaction((transaction) async {
        final bookingDoc = await transaction.get(bookingRef);
        final slotDoc = await transaction.get(slotRef);

        if (!bookingDoc.exists) {
          result = const QrValidationResult(
              valid: false, message: 'Booking not found');
          return;
        }

        final bookingData = bookingDoc.data()!;
        final bookingStatus = bookingData['status'] as String;
        final slotStatus = slotDoc.data()?['status'] as String?;

        if (bookingStatus != AppConstants.bookingActive) {
          result = QrValidationResult(
              valid: false,
              message: 'Booking is $bookingStatus — not active');
          return;
        }

        if (slotStatus == AppConstants.slotOccupied) {
          result = const QrValidationResult(
              valid: false, message: 'Slot already occupied');
          return;
        }

        // Mark occupied
        transaction
            .update(slotRef, {'status': AppConstants.slotOccupied});
        transaction
            .update(bookingRef, {'status': AppConstants.bookingCompleted});

        result = QrValidationResult(
          valid: true,
          message: 'Valid Booking ✓',
          bookingId: bookingId,
          slotId: slotId,
          locationName: bookingData['locationName'] ?? '',
          slotNumber: bookingData['slotNumber'] ?? '',
        );
      });

      return result;
    } catch (e) {
      return QrValidationResult(valid: false, message: 'Invalid QR code: $e');
    }
  }

  Map<String, dynamic> _parseQrPayload(String payload) {
    return json.decode(payload) as Map<String, dynamic>;
  }
}

class QrValidationResult {
  final bool valid;
  final String message;
  final String? bookingId;
  final String? slotId;
  final String? locationName;
  final String? slotNumber;

  const QrValidationResult({
    required this.valid,
    required this.message,
    this.bookingId,
    this.slotId,
    this.locationName,
    this.slotNumber,
  });
}
