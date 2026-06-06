import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../services/firestore_service.dart';
import '../../../models/parking_location_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  GoogleMapController? _mapController;

  static const String _darkMapStyle = '''[
    {"elementType": "geometry", "stylers": [{"color": "#212121"}]},
    {"elementType": "labels.text.fill", "stylers": [{"color": "#757575"}]},
    {"elementType": "labels.text.stroke", "stylers": [{"color": "#212121"}]},
    {"featureType": "road", "elementType": "geometry", "stylers": [{"color": "#373737"}]},
    {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#000000"}]}
  ]''';

  static const CameraPosition _dubaiCenter = CameraPosition(
    target: LatLng(AppConstants.dubaiLat, AppConstants.dubaiLng),
    zoom: 11,
  );

  // We default to the Mock Map for stability. The user can switch to Google Maps if their API key is working.
  bool _useGoogleMaps = false;

  @override
  Widget build(BuildContext context) {
    final locationsStream =
        ref.watch(firestoreServiceProvider).getParkingLocations();

    final bool isApiKeyConfigured =
        AppConstants.googleMapsApiKey != 'YOUR_GOOGLE_MAPS_API_KEY' &&
            AppConstants.googleMapsApiKey.trim().isNotEmpty;

    // Use Mock Map if user hasn't switched to Google Maps, or if the API key isn't set.
    final bool showMockMap = !_useGoogleMaps || !isApiKeyConfigured;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Parking'),
        leading: BackButton(onPressed: () => context.pop()),
        actions: [
          if (isApiKeyConfigured)
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _useGoogleMaps = !_useGoogleMaps;
                });
              },
              icon: Icon(
                _useGoogleMaps ? Icons.grid_view_rounded : Icons.map_rounded,
                size: 18,
                color: AppTheme.primaryColor,
              ),
              label: Text(
                _useGoogleMaps ? 'Offline Map' : 'Google Maps',
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: StreamBuilder<List<ParkingLocationModel>>(
        stream: locationsStream,
        builder: (context, snapshot) {
          final locations = snapshot.data ?? [];

          // Generate map markers inline during build to avoid triggering infinite rebuild loops (setState inside builder)
          final Set<Marker> googleMapMarkers = locations.map((loc) {
            return Marker(
              markerId: MarkerId(loc.locationId),
              position: LatLng(loc.lat, loc.lng),
              infoWindow: InfoWindow(
                title: loc.name,
                snippet: 'Tap to view slots',
                onTap: () => context.push(
                  '/parking/${loc.locationId}?name=${Uri.encodeComponent(loc.name)}',
                ),
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueGreen,
              ),
            );
          }).toSet();

          return Stack(
            children: [
              if (showMockMap)
                _buildMockMap(context, locations, isApiKeyConfigured)
              else
                GoogleMap(
                  initialCameraPosition: _dubaiCenter,
                  markers: googleMapMarkers,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: true,
                  mapType: MapType.normal,
                  style: _darkMapStyle,
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                ),

              // Bottom Sheet with location list
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                    border: Border(
                      top: BorderSide(color: AppTheme.borderColor),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.borderColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Text(
                              'Nearby Parking',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const Spacer(),
                            if (snapshot.hasData)
                              Text(
                                '${locations.length} locations',
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (snapshot.connectionState == ConnectionState.waiting)
                        const Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(
                              color: AppTheme.primaryColor),
                        )
                      else if (locations.isNotEmpty)
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          itemCount: locations.length,
                          itemBuilder: (context, index) {
                            final location = locations[index];
                            return _LocationTile(
                              location: location,
                              onTap: () {
                                if (!showMockMap) {
                                  _animateTo(location.lat, location.lng);
                                }
                                context.push(
                                  '/parking/${location.locationId}?name=${Uri.encodeComponent(location.name)}',
                                );
                              },
                            );
                          },
                        )
                      else
                        const Padding(
                          padding: EdgeInsets.all(20),
                          child: Text(
                            'No parking locations found',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMockMap(BuildContext context, List<ParkingLocationModel> locations,
      bool isApiKeyConfigured) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final double height = constraints.maxHeight;

        return Stack(
          children: [
            // Dark futuristic grid painter
            Positioned.fill(
              child: CustomPaint(
                painter: _MockGridPainter(),
              ),
            ),

            // Pulsing Interactive Markers
            ...locations.map((loc) {
              double left = 0.0;
              double top = 0.0;
              if (loc.name.contains('Dubai Mall')) {
                left = width * 0.65;
                top = height * 0.35;
              } else if (loc.name.contains('Marina Mall')) {
                left = width * 0.25;
                top = height * 0.52;
              } else {
                left = width * 0.5;
                top = height * 0.45;
              }

              return Positioned(
                left: left - 20,
                top: top - 20,
                child: _PulsingMarker(
                  locationName: loc.name,
                  onTap: () {
                    context.push(
                      '/parking/${loc.locationId}?name=${Uri.encodeComponent(loc.name)}',
                    );
                  },
                ),
              );
            }),

            // Status warning banner
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isApiKeyConfigured
                      ? AppTheme.primaryColor.withValues(alpha: 0.12)
                      : AppTheme.secondaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isApiKeyConfigured
                        ? AppTheme.primaryColor.withValues(alpha: 0.25)
                        : AppTheme.secondaryColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isApiKeyConfigured
                          ? Icons.check_circle_outline_rounded
                          : Icons.info_outline_rounded,
                      color: isApiKeyConfigured
                          ? AppTheme.primaryColor
                          : AppTheme.secondaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isApiKeyConfigured
                            ? 'Google Maps API Key loaded successfully. Tap "Google Maps" at the top to load real maps.'
                            : 'Google Maps Key not configured. Using interactive Offline Map.',
                        style: TextStyle(
                          color: isApiKeyConfigured
                              ? AppTheme.primaryColor
                              : AppTheme.secondaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _animateTo(double lat, double lng) {
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(lat, lng), 15),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}

class _LocationTile extends StatelessWidget {
  final ParkingLocationModel location;
  final VoidCallback onTap;

  const _LocationTile({required this.location, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.local_parking_rounded,
                  color: AppTheme.primaryColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    location.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    location.address,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _MockGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFF1F2E24).withValues(alpha: 0.3)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final radarPaint = Paint()
      ..color = const Color(0xFF1F2E24).withValues(alpha: 0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final coastPaint = Paint()
      ..color = AppTheme.primaryColor.withValues(alpha: 0.2)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    // Draw Grid Lines
    const double step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Draw Radar Circles at center
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(center, 80, radarPaint);
    canvas.drawCircle(center, 160, radarPaint);
    canvas.drawCircle(center, 240, radarPaint);

    // Draw coastal curve of Dubai
    final path = Path()
      ..moveTo(0, size.height * 0.75)
      ..quadraticBezierTo(
        size.width * 0.4,
        size.height * 0.5,
        size.width,
        size.height * 0.35,
      );
    canvas.drawPath(path, coastPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PulsingMarker extends StatefulWidget {
  final String locationName;
  final VoidCallback onTap;

  const _PulsingMarker({required this.locationName, required this.onTap});

  @override
  State<_PulsingMarker> createState() => _PulsingMarkerState();
}

class _PulsingMarkerState extends State<_PulsingMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: 60,
        height: 60,
        color: Colors.transparent,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Pulsing outer ring
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Container(
                  width: 50 * _animation.value,
                  height: 50 * _animation.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primaryColor
                        .withValues(alpha: 0.8 * (1.0 - _animation.value)),
                  ),
                );
              },
            ),
            // Core marker pin
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.local_parking_rounded,
                  color: Colors.black,
                  size: 16,
                ),
              ),
            ),
            // Location Label
            Positioned(
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Text(
                  widget.locationName.split(' ').first,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
