import 'package:cloud_firestore/cloud_firestore.dart';

class ParkingLocationModel {
  final String locationId;
  final String name;
  final String address;
  final double lat;
  final double lng;
  final int totalSlots;

  const ParkingLocationModel({
    required this.locationId,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    required this.totalSlots,
  });

  factory ParkingLocationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ParkingLocationModel(
      locationId: doc.id,
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      lat: (data['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (data['lng'] as num?)?.toDouble() ?? 0.0,
      totalSlots: (data['totalSlots'] as num?)?.toInt() ?? 10,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'lat': lat,
      'lng': lng,
      'totalSlots': totalSlots,
    };
  }
}
