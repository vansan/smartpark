class AppConstants {
  // App
  static const String appName = 'SmartPark';
  static const String appVersion = '1.0.0 POC';

  // Firestore Collections
  static const String usersCollection = 'users';
  static const String parkingLocationsCollection = 'parking_locations';
  static const String parkingSlotsCollection = 'parking_slots';
  static const String bookingsCollection = 'bookings';

  // Slot Status
  static const String slotFree = 'free';
  static const String slotBooked = 'booked';
  static const String slotOccupied = 'occupied';

  // Booking Status
  static const String bookingActive = 'active';
  static const String bookingCompleted = 'completed';
  static const String bookingCancelled = 'cancelled';

  // Google Maps
  // TODO: Replace with your actual Google Maps API key
  static const String googleMapsApiKey = 'AIzaSyD1TWbMv6oxQ3qMB1Oh9JIYMGCwEYuHDcA';

  // Dubai Coordinates (center)
  static const double dubaiLat = 25.2048;
  static const double dubaiLng = 55.2708;
}
