import 'package:cloud_firestore/cloud_firestore.dart';

class ParkingSlotModel {
  final String slotId;
  final String locationId;
  final String slotNumber;
  final String status; // free, booked, occupied

  const ParkingSlotModel({
    required this.slotId,
    required this.locationId,
    required this.slotNumber,
    required this.status,
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
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'locationId': locationId,
      'slotNumber': slotNumber,
      'status': status,
    };
  }

  ParkingSlotModel copyWith({String? status}) {
    return ParkingSlotModel(
      slotId: slotId,
      locationId: locationId,
      slotNumber: slotNumber,
      status: status ?? this.status,
    );
  }
}
