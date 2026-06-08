import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  final String bookingId;
  final String userId;
  final String slotId;
  final String locationId;
  final String slotNumber;
  final String locationName;
  final DateTime createdAt;
  final DateTime startTime;
  final DateTime endTime;
  final int durationHours;
  final double amountPaid;
  final String status; // active, completed, cancelled
  final double locationLat;
  final double locationLng;

  const BookingModel({
    required this.bookingId,
    required this.userId,
    required this.slotId,
    required this.locationId,
    required this.slotNumber,
    required this.locationName,
    required this.createdAt,
    required this.startTime,
    required this.endTime,
    required this.durationHours,
    required this.amountPaid,
    required this.status,
    this.locationLat = 0.0,
    this.locationLng = 0.0,
  });

  bool get isExpired =>
      status == 'active' && DateTime.now().isAfter(endTime);

  Duration get timeRemaining {
    final remaining = endTime.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  double get effectiveLat {
    if (locationLat != 0.0) return locationLat;
    if (locationId == 'dubai_mall') return 25.1972;
    if (locationId == 'marina_mall') return 25.0771;
    return 0.0;
  }

  double get effectiveLng {
    if (locationLng != 0.0) return locationLng;
    if (locationId == 'dubai_mall') return 55.2796;
    if (locationId == 'marina_mall') return 55.1330;
    return 0.0;
  }

  bool get hasCoordinates => effectiveLat != 0.0 && effectiveLng != 0.0;

  factory BookingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final now = DateTime.now();
    return BookingModel(
      bookingId: doc.id,
      userId: data['userId'] ?? '',
      slotId: data['slotId'] ?? '',
      locationId: data['locationId'] ?? '',
      slotNumber: data['slotNumber'] ?? '',
      locationName: data['locationName'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? now,
      startTime: (data['startTime'] as Timestamp?)?.toDate() ?? now,
      endTime: (data['endTime'] as Timestamp?)?.toDate() ??
          now.add(const Duration(hours: 1)),
      durationHours: (data['durationHours'] as int?) ?? 1,
      amountPaid: (data['amountPaid'] as num?)?.toDouble() ?? 0.0,
      status: data['status'] ?? 'active',
      locationLat: (data['locationLat'] as num?)?.toDouble() ?? 0.0,
      locationLng: (data['locationLng'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'slotId': slotId,
      'locationId': locationId,
      'slotNumber': slotNumber,
      'locationName': locationName,
      'createdAt': Timestamp.fromDate(createdAt),
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'durationHours': durationHours,
      'amountPaid': amountPaid,
      'status': status,
      'locationLat': locationLat,
      'locationLng': locationLng,
    };
  }

  /// Generates a JSON string payload for QR code
  String toQrPayload() {
    return jsonEncode({
      'bookingId': bookingId,
      'slotId': slotId,
      'userId': userId,
    });
  }

  /// Google Maps directions URL
  String get directionsUrl =>
      'https://www.google.com/maps/dir/?api=1'
      '&destination=$effectiveLat,$effectiveLng'
      '&travelmode=driving';
}
