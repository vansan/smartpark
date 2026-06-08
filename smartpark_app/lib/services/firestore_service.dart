import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_constants.dart';
import '../models/parking_location_model.dart';
import '../models/parking_slot_model.dart';
import '../models/booking_model.dart';

final firestoreServiceProvider =
    Provider<FirestoreService>((ref) => FirestoreService());

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── Parking Locations ───────────────────────────────────────────────────

  Stream<List<ParkingLocationModel>> getParkingLocations() {
    return _db
        .collection(AppConstants.parkingLocationsCollection)
        .snapshots()
        .map((snap) =>
            snap.docs.map(ParkingLocationModel.fromFirestore).toList());
  }

  // ─── Parking Slots ───────────────────────────────────────────────────────

  Stream<List<ParkingSlotModel>> getSlotsForLocation(String locationId) {
    return _db
        .collection(AppConstants.parkingSlotsCollection)
        .where('locationId', isEqualTo: locationId)
        .snapshots()
        .map((snap) {
      final list =
          snap.docs.map(ParkingSlotModel.fromFirestore).toList();
      // Sort locally to avoid needing a Firestore composite index
      list.sort((a, b) => a.slotNumber.compareTo(b.slotNumber));
      // Trigger expiry check as a fire-and-forget side-effect
      checkAndReleaseExpiredBookingsForLocation(locationId);
      return list;
    });
  }

  // ─── Bookings ─────────────────────────────────────────────────────────────

  Stream<List<BookingModel>> getActiveBookingsForUser(String userId) {
    // Fire-and-forget expiry check for this user
    releaseExpiredBookingsForUser(userId);

    return _db
        .collection(AppConstants.bookingsCollection)
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: AppConstants.bookingActive)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map(BookingModel.fromFirestore).toList();
      // Sort locally to avoid needing a Firestore composite index
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<BookingModel?> getBookingById(String bookingId) async {
    final doc = await _db
        .collection(AppConstants.bookingsCollection)
        .doc(bookingId)
        .get();
    if (!doc.exists) return null;
    return BookingModel.fromFirestore(doc);
  }

  /// Cancel a booking early and release the slot back to free.
  Future<void> cancelBooking(String bookingId, String slotId) async {
    final batch = _db.batch();
    batch.update(
      _db.collection(AppConstants.bookingsCollection).doc(bookingId),
      {'status': AppConstants.bookingCancelled},
    );
    batch.update(
      _db.collection(AppConstants.parkingSlotsCollection).doc(slotId),
      {'status': AppConstants.slotFree},
    );
    await batch.commit();
  }

  // ─── Auto-Release Expired Bookings ───────────────────────────────────────

  /// Client-side expiry check: releases all expired active bookings for a location.
  /// Fire-and-forget — call without await to avoid blocking the UI.
  Future<void> checkAndReleaseExpiredBookingsForLocation(
      String locationId) async {
    try {
      final now = Timestamp.now();
      final snap = await _db
          .collection(AppConstants.bookingsCollection)
          .where('locationId', isEqualTo: locationId)
          .where('status', isEqualTo: AppConstants.bookingActive)
          .where('endTime', isLessThanOrEqualTo: now)
          .get();

      if (snap.docs.isEmpty) return;

      final batch = _db.batch();
      for (final doc in snap.docs) {
        final slotId = doc.data()['slotId'] as String?;
        batch.update(doc.reference, {'status': AppConstants.bookingCompleted});
        if (slotId != null) {
          batch.update(
            _db
                .collection(AppConstants.parkingSlotsCollection)
                .doc(slotId),
            {'status': AppConstants.slotFree},
          );
        }
      }
      await batch.commit();
    } catch (_) {
      // Silently swallow errors — this is a background best-effort operation
    }
  }

  /// Client-side expiry check: releases all expired active bookings for a user.
  Future<void> releaseExpiredBookingsForUser(String userId) async {
    try {
      final now = Timestamp.now();
      final snap = await _db
          .collection(AppConstants.bookingsCollection)
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: AppConstants.bookingActive)
          .where('endTime', isLessThanOrEqualTo: now)
          .get();

      if (snap.docs.isEmpty) return;

      final batch = _db.batch();
      for (final doc in snap.docs) {
        final slotId = doc.data()['slotId'] as String?;
        batch.update(doc.reference, {'status': AppConstants.bookingCompleted});
        if (slotId != null) {
          batch.update(
            _db
                .collection(AppConstants.parkingSlotsCollection)
                .doc(slotId),
            {'status': AppConstants.slotFree},
          );
        }
      }
      await batch.commit();
    } catch (_) {
      // Silently swallow errors
    }
  }

  // ─── Seed Mock Data ───────────────────────────────────────────────────────

  /// Seeds 2 parking locations with 10 slots each into Firestore.
  /// Safe to call multiple times — checks if data exists first.
  Future<void> seedMockData() async {
    final locSnap =
        await _db.collection(AppConstants.parkingLocationsCollection).get();

    // Check if coordinates are missing in any of the seeded documents
    bool needsCoordinatesUpdate = false;
    for (var doc in locSnap.docs) {
      final data = doc.data();
      if (data['lat'] == null ||
          data['lat'] == 0.0 ||
          data['lng'] == null ||
          data['lng'] == 0.0) {
        needsCoordinatesUpdate = true;
        break;
      }
    }

    final slotsSnap = await _db.collection(AppConstants.parkingSlotsCollection).limit(1).get();
    if (slotsSnap.docs.isEmpty) {
      needsCoordinatesUpdate = true;
    } else {
      final firstSlot = slotsSnap.docs.first.data();
      if (firstSlot['lat'] == null || firstSlot['lat'] == 0.0) {
        needsCoordinatesUpdate = true;
      }
    }

    if (locSnap.docs.isNotEmpty && !needsCoordinatesUpdate) return; // already seeded and has coordinates

    final locations = [
      {
        'id': 'dubai_mall',
        'name': 'Dubai Mall Parking',
        'address': 'Financial Centre Rd, Downtown Dubai',
        'lat': 25.1972,
        'lng': 55.2796,
        'totalSlots': 10,
      },
      {
        'id': 'marina_mall',
        'name': 'Marina Mall Parking',
        'address': 'Al Marsa St, Dubai Marina',
        'lat': 25.0771,
        'lng': 55.1330,
        'totalSlots': 10,
      },
    ];

    final batch = _db.batch();

    for (final loc in locations) {
      final locRef = _db
          .collection(AppConstants.parkingLocationsCollection)
          .doc(loc['id'] as String);
      
      batch.set(
        locRef,
        {
          'name': loc['name'],
          'address': loc['address'],
          'lat': loc['lat'],
          'lng': loc['lng'],
          'totalSlots': loc['totalSlots'],
        },
        SetOptions(merge: true),
      );

      // Seed/update slots with specific parking structure coordinates
      for (int i = 1; i <= 10; i++) {
        final slotRef = _db
            .collection(AppConstants.parkingSlotsCollection)
            .doc('${loc['id']}_slot_$i');

        double slotLat = loc['lat'] as double;
        double slotLng = loc['lng'] as double;
        String sectionName = '';

        if (loc['id'] == 'dubai_mall') {
          if (i <= 3) {
            sectionName = 'Grand Parking';
            slotLat = 25.1960;
            slotLng = 55.2785;
          } else if (i <= 6) {
            sectionName = 'Fashion Parking';
            slotLat = 25.1980;
            slotLng = 55.2795;
          } else {
            sectionName = 'Cinema Parking';
            slotLat = 25.2005;
            slotLng = 55.2770;
          }
        } else if (loc['id'] == 'marina_mall') {
          if (i <= 5) {
            sectionName = 'Level P1 (Grand)';
            slotLat = 25.0770;
            slotLng = 55.1335;
          } else {
            sectionName = 'Level P2 (Cinema)';
            slotLat = 25.0775;
            slotLng = 55.1325;
          }
        }

        batch.set(
          slotRef,
          {
            'locationId': loc['id'],
            'slotNumber': 'P${i.toString().padLeft(2, '0')}',
            'lat': slotLat,
            'lng': slotLng,
            'sectionName': sectionName,
          },
          SetOptions(merge: true),
        );
      }
    }

    await batch.commit();
  }
}
