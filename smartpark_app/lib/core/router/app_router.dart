import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/map/screens/map_screen.dart';
import '../../features/parking/screens/parking_detail_screen.dart';
import '../../features/parking/screens/my_bookings_screen.dart';
import '../../features/parking/screens/booking_qr_screen.dart';
import '../../features/parking/screens/payment_summary_screen.dart';
import '../../features/guard/screens/guard_screen.dart';
import '../../models/parking_slot_model.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final isLoginPage = state.matchedLocation == '/login';

      if (!isLoggedIn && !isLoginPage) return '/login';
      if (isLoggedIn && isLoginPage) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/map',
        name: 'map',
        builder: (context, state) => const MapScreen(),
      ),
      GoRoute(
        path: '/parking/:locationId',
        name: 'parking-detail',
        builder: (context, state) {
          final locationId = state.pathParameters['locationId']!;
          final locationName =
              state.uri.queryParameters['name'] ?? 'Parking';
          return ParkingDetailScreen(
            locationId: locationId,
            locationName: locationName,
          );
        },
      ),
      GoRoute(
        path: '/payment-summary',
        name: 'payment-summary',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return PaymentSummaryScreen(
            slot: extra['slot'] as ParkingSlotModel,
            locationId: extra['locationId'] as String,
            locationName: extra['locationName'] as String,
            startTime: extra['startTime'] as DateTime,
            endTime: extra['endTime'] as DateTime,
            durationHours: extra['durationHours'] as int,
            total: extra['total'] as double,
          );
        },
      ),
      GoRoute(
        path: '/my-bookings',
        name: 'my-bookings',
        builder: (context, state) => const MyBookingsScreen(),
      ),
      GoRoute(
        path: '/booking-qr/:bookingId',
        name: 'booking-qr',
        builder: (context, state) {
          final bookingId = state.pathParameters['bookingId']!;
          return BookingQrScreen(bookingId: bookingId);
        },
      ),
      GoRoute(
        path: '/guard',
        name: 'guard',
        builder: (context, state) => const GuardScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.error}'),
      ),
    ),
  );
});
