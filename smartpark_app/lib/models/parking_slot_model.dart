import 'package:cloud_firestore/cloud_firestore.dart';

class ParkingSlotModel {
  final String slotId;
  final String locationId;
  final String slotNumber;
  final String status; // free, booked, occupied
  final double lat;
  final double lng;
  final String sectionName; // e.g. Grand Parking, Fashion Parking, Cinema Parking

  const ParkingSlotModel({
    required this.slotId,
    required this.locationId,
    required this.slotNumber,
    required this.status,
    this.lat = 0.0,
    this.lng = 0.0,
    this.sectionName = '',
  });

  bool get isFree => status == 'free';
  bool get isBooked => status == 'booked';
  bool get isOccupied => status == 'occupied';

  factory ParkingSlotModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ParkingSlotModel(
      slotId: doc.id,
      locationId: data['locationId'] ?? '',
      slotNumber: data['slotNumber'] ?? '',
      status: data['status'] ?? 'free',
      lat: (data['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (data['lng'] as num?)?.toDouble() ?? 0.0,
      sectionName: data['sectionName'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'locationId': locationId,
      'slotNumber': slotNumber,
      'status': status,
      'lat': lat,
      'lng': lng,
      'sectionName': sectionName,
    };
  }

  ParkingSlotModel copyWith({
    String? status,
    double? lat,
    double? lng,
    String? sectionName,
  }) {
    return ParkingSlotModel(
      slotId: slotId,
      locationId: locationId,
      slotNumber: slotNumber,
      status: status ?? this.status,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      sectionName: sectionName ?? this.sectionName,
    );
  }
}
